import { useBackend } from '../backend';
import { Component, createRef } from 'inferno';
import { Box, Button, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';

const MIN_SCALE = 1;
const MAX_SCALE = 8;
const DEFAULT_SCALE = 3;
const AUTO_FOCUS_SCALE = 6;
const FOG_COLOR = [8, 14, 10];

const hexify = (num) => {
  if (!num) {
    num = 0;
  }
  num = num.toString(16);
  if (num.length === 1) {
    num = '0' + num;
  }
  return num;
};

const colorAt = (imageData, x, y) => {
  const i = (x + y * imageData.width) * 4;
  return '#'
    + hexify(imageData.data[i])
    + hexify(imageData.data[i + 1])
    + hexify(imageData.data[i + 2]);
};

// Fully explored (Pip-Boy style) world map, one z-level shown at a time:
// - hover the map to read the area name under the cursor
// - only areas you've physically visited are revealed (fog of war)
// - your own position is shown live, click the map to drop a waypoint
//
// The canvas is never removed/replaced by hand -- Inferno owns that DOM
// node for the lifetime of the component, we only ever draw into it via
// its 2d context. (An earlier version swapped <img> for a hand-built
// <canvas> and got stuck showing whatever was drawn first, because
// Inferno kept diffing against its own now-detached reference to the
// original <img>.)
export class Minimap extends Component {
  constructor() {
    super();
    this.state = {
      selectedIndex: 0,
      scale: DEFAULT_SCALE,
      panX: 0,
      panY: 0,
      hoverLabel: '',
    };
    this.canvasRef = createRef();
    this.mapImgRef = createRef();
    this.metaImgRef = createRef();
    this.loadedIndex = -1;
    this.lastRevealedKey = null;
    this.width = 0;
    this.height = 0;
    this.isPanning = false;
    this.didPan = false;
    // Only auto-jump to the mob's current map once, so it doesn't yank the
    // player back after they've deliberately picked a different tab.
    this.didAutoSelect = false;
    // Only auto-center/zoom on the player's blip once (the first time
    // it's available after a map finishes loading), same reasoning as
    // didAutoSelect above.
    this.didAutoCenter = false;
    this.loadStartedAt = Date.now();
  }

  componentWillUnmount() {
    clearInterval(this.loadTicker);
  }

  // Draws the currently-selected map's images into the (already-mounted)
  // canvas. No-ops until both the visible image and the hidden meta
  // image have decoded.
  loadActiveMap() {
    const { selectedIndex } = this.state;
    if (this.loadedIndex === selectedIndex) {
      return;
    }
    const img = this.mapImgRef.current;
    const metaImg = this.metaImgRef.current;
    const canvas = this.canvasRef.current;
    if (!img || !metaImg || !canvas) {
      return;
    }
    const imgReady = img.complete && img.naturalWidth;
    const metaReady = metaImg.complete && metaImg.naturalWidth;
    if (!imgReady || !metaReady) {
      return;
    }

    canvas.width = img.naturalWidth;
    canvas.height = img.naturalHeight;
    const ctx = canvas.getContext('2d');
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(img, 0, 0);

    const metaCanvas = document.createElement('canvas');
    metaCanvas.width = metaImg.naturalWidth;
    metaCanvas.height = metaImg.naturalHeight;
    const metaCtx = metaCanvas.getContext('2d');
    metaCtx.drawImage(metaImg, 0, 0);

    this.ctx = ctx;
    this.width = img.naturalWidth;
    this.height = img.naturalHeight;
    this.baseImageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    this.metaImageData = metaCtx.getImageData(
      0, 0, metaCanvas.width, metaCanvas.height,
    );
    this.loadedIndex = selectedIndex;
    this.lastRevealedKey = null;
    this.applyFog(null);
    this.forceUpdate();
  }

  // Repaints the map canvas from the pristine base image, blacking out
  // any pixel whose chunk color hasn't been revealed yet. Skips the
  // (somewhat expensive) repaint if the revealed set hasn't actually
  // grown since last time.
  applyFog(revealedColors) {
    if (!this.ctx || !this.baseImageData) {
      return;
    }
    const key = revealedColors
      ? revealedColors.slice().sort().join(',')
      : 'ALL';
    if (key === this.lastRevealedKey) {
      return;
    }
    this.lastRevealedKey = key;

    if (!revealedColors) {
      this.ctx.putImageData(this.baseImageData, 0, 0);
      return;
    }

    const revealed = new Set(revealedColors.map((c) => c.toLowerCase()));
    const base = this.baseImageData;
    const meta = this.metaImageData;
    const out = this.ctx.createImageData(base.width, base.height);
    for (let py = 0; py < base.height; py++) {
      for (let px = 0; px < base.width; px++) {
        const idx = (px + py * base.width) * 4;
        const color = colorAt(meta, px, py);
        if (revealed.has(color)) {
          out.data[idx] = base.data[idx];
          out.data[idx + 1] = base.data[idx + 1];
          out.data[idx + 2] = base.data[idx + 2];
        } else {
          out.data[idx] = FOG_COLOR[0];
          out.data[idx + 1] = FOG_COLOR[1];
          out.data[idx + 2] = FOG_COLOR[2];
        }
        out.data[idx + 3] = 255;
      }
    }
    this.ctx.putImageData(out, 0, 0);
  }

  handleMapHover(e, selectedIndex) {
    if (!this.metaImageData) {
      return;
    }
    const rect = this.canvasRef.current.getBoundingClientRect();
    const x = Math.floor((e.clientX - rect.left) * this.width / rect.width);
    const y = Math.floor((e.clientY - rect.top) * this.height / rect.height);
    if (x < 0 || y < 0 || x >= this.width || y >= this.height) {
      return;
    }
    const { data } = useBackend(this.context);
    const color = colorAt(this.metaImageData, x, y);
    const mapData = data.maps?.[selectedIndex];
    const colorAreaNames = mapData?.colorAreaNames || {};
    this.setState({ hoverLabel: colorAreaNames[color] || '' });
  }

  handleMapClick(e) {
    if (this.didPan) {
      this.didPan = false;
      return;
    }
    if (!this.width) {
      return;
    }
    const { act } = useBackend(this.context);
    const rect = this.canvasRef.current.getBoundingClientRect();
    const x = Math.floor((e.clientX - rect.left) * this.width / rect.width);
    const y = Math.floor((e.clientY - rect.top) * this.height / rect.height);
    act('set_waypoint', { mapIndex: this.state.selectedIndex + 1, x, y });
  }

  handlePanStart(e) {
    this.isPanning = true;
    this.didPan = false;
    this.panStartX = e.clientX;
    this.panStartY = e.clientY;
    this.panOriginX = this.state.panX;
    this.panOriginY = this.state.panY;
    const stopPan = () => {
      this.isPanning = false;
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', stopPan);
    };
    const onMove = (moveEvent) => {
      if (!this.isPanning) {
        return;
      }
      const dx = moveEvent.clientX - this.panStartX;
      const dy = moveEvent.clientY - this.panStartY;
      if (Math.abs(dx) > 3 || Math.abs(dy) > 3) {
        this.didPan = true;
      }
      this.setState((prevState) => ({
        panX: this.panOriginX + dx / prevState.scale,
        panY: this.panOriginY + dy / prevState.scale,
      }));
    };
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', stopPan);
  }

  handleWheel(e) {
    e.preventDefault();
    const delta = e.deltaY > 0 ? -0.5 : 0.5;
    this.setState((prevState) => ({
      scale: Math.min(MAX_SCALE, Math.max(MIN_SCALE, prevState.scale + delta)),
    }));
  }

  resetView() {
    this.setState({ scale: DEFAULT_SCALE, panX: 0, panY: 0 });
  }

  // Centers the viewport on a canvas-space (x, y) pixel and zooms in, by
  // translating in the Stage's own local/unscaled units -- panX/panY
  // apply before scale() in the CSS transform, so the offset needed to
  // center a point doesn't depend on the target scale.
  centerOn(x, y, scale) {
    const canvas = this.canvasRef.current;
    if (!canvas || !this.width || !this.height) {
      return;
    }
    const rect = canvas.getBoundingClientRect();
    const baseWidth = rect.width / this.state.scale;
    const baseHeight = rect.height / this.state.scale;
    const panX = (0.5 - x / this.width) * baseWidth;
    const panY = (0.5 - y / this.height) * baseHeight;
    this.setState({ scale, panX, panY });
  }

  selectMap(index) {
    if (index === this.state.selectedIndex) {
      return;
    }
    this.loadedIndex = -1;
    this.loadStartedAt = Date.now();
    this.setState({
      selectedIndex: index,
      scale: DEFAULT_SCALE,
      panX: 0,
      panY: 0,
      hoverLabel: '',
    });
  }

  componentDidMount() {
    this.loadActiveMap();
    // Ticks the "Loading map... Ns" label while the active map's
    // images are still decoding.
    this.loadTicker = setInterval(() => {
      if (this.loadedIndex !== this.state.selectedIndex) {
        this.forceUpdate();
      }
    }, 250);
  }

  componentDidUpdate() {
    const { data } = useBackend(this.context);
    if (!this.didAutoSelect && data.blip) {
      this.didAutoSelect = true;
      if (data.blip.mapIndex - 1 !== this.state.selectedIndex) {
        this.selectMap(data.blip.mapIndex - 1);
        return;
      }
    }
    this.loadActiveMap();
    const revealedColors = data.revealedColors || [];
    this.applyFog(revealedColors[this.state.selectedIndex]);
    if (
      !this.didAutoCenter
      && this.loadedIndex === this.state.selectedIndex
      && data.blip
      && data.blip.mapIndex - 1 === this.state.selectedIndex
    ) {
      this.didAutoCenter = true;
      this.centerOn(data.blip.x, data.blip.y, AUTO_FOCUS_SCALE);
    }
  }

  // Renders the pannable/zoomable map canvas, the loading overlay, and
  // the live blip/waypoint markers. Split out of render() so the JSX
  // tree above it doesn't get too deeply nested.
  renderViewport({ activeMap, blip, waypoint, selectedIndex }) {
    const { scale, panX, panY } = this.state;
    const isLoading = this.loadedIndex !== selectedIndex;
    const showBlip = blip
      && blip.mapIndex - 1 === selectedIndex
      && this.width;
    const showWaypoint = waypoint
      && waypoint.mapIndex - 1 === selectedIndex
      && this.width;
    const loadedSeconds = Math.floor(
      (Date.now() - this.loadStartedAt) / 1000,
    );
    const stageStyle = {
      transform: `scale(${scale}) translate(${panX}px, ${panY}px)`,
    };

    return (
      <Box
        className="Minimap__Viewport"
        onWheel={(e) => this.handleWheel(e)}>
        {isLoading && (
          <Box className="Minimap__Loading">
            Loading map... {loadedSeconds}s
          </Box>
        )}
        <Box className="Minimap__Stage" style={stageStyle}>
          <Box className="Minimap__CanvasWrap">
            <canvas
              ref={this.canvasRef}
              className="Minimap__Canvas"
              onMouseMove={(e) => this.handleMapHover(e, selectedIndex)}
              onMouseOut={() => this.setState({ hoverLabel: '' })}
              onMouseDown={(e) => this.handlePanStart(e)}
              onClick={(e) => this.handleMapClick(e)} />
            {!!showBlip && (
              <Box
                className="Minimap__Blip"
                style={{
                  left: `${((blip.x + 0.5) / this.width) * 100}%`,
                  top: `${((blip.y + 0.5) / this.height) * 100}%`,
                }} />
            )}
            {!!showWaypoint && (
              <Box
                className="Minimap__Waypoint"
                style={{
                  left: `${((waypoint.x + 0.5) / this.width) * 100}%`,
                  top: `${((waypoint.y + 0.5) / this.height) * 100}%`,
                }} />
            )}
          </Box>
        </Box>
        <img
          ref={this.mapImgRef}
          style={{ display: 'none' }}
          src={activeMap?.mapUrl}
          onLoad={() => this.loadActiveMap()} />
        <img
          ref={this.metaImgRef}
          style={{ display: 'none' }}
          src={activeMap?.metaUrl}
          onLoad={() => this.loadActiveMap()} />
      </Box>
    );
  }

  render() {
    const { act, data } = useBackend(this.context);
    const {
      title = 'World Map',
      maps = [],
      revealedColors = [],
      blip,
      waypoint,
    } = data;
    const { selectedIndex, hoverLabel } = this.state;
    const activeMap = maps[selectedIndex];

    const activeRevealed = revealedColors[selectedIndex];
    const seenNames = new Set();
    const legendEntries = Object.entries(activeMap?.colorAreaNames || {})
      .filter(([color]) => !activeRevealed || activeRevealed.includes(color))
      .filter(([, areaName]) => (
        !seenNames.has(areaName) && seenNames.add(areaName)
      ))
      .map(([color, areaName]) => ({ color, areaName }))
      .sort((a, b) => a.areaName.localeCompare(b.areaName));

    return (
      <Window title={title} theme="fallout" width={680} height={800}>
        <Window.Content className="Minimap" scrollable={false}>
          <Stack vertical fill>
            <Stack.Item>
              <Tabs>
                {maps.map((map, i) => (
                  <Tabs.Tab
                    key={map.name}
                    selected={i === selectedIndex}
                    onClick={() => this.selectMap(i)}>
                    {map.name}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Stack.Item>
            <Stack.Item grow>
              <Section
                fill
                title={activeMap?.name}
                buttons={(
                  <>
                    <Button
                      icon="crosshairs"
                      content="Reset View"
                      onClick={() => this.resetView()} />
                    {!!waypoint && (
                      <Button
                        icon="times"
                        content="Clear Waypoint"
                        onClick={() => act('clear_waypoint')} />
                    )}
                  </>
                )}>
                <Stack vertical fill>
                  <Stack.Item>
                    <Box className="Minimap__Label">
                      {hoverLabel || '\u00A0'}
                    </Box>
                  </Stack.Item>
                  <Stack.Item grow>
                    <Stack fill>
                      <Stack.Item grow>
                        {this.renderViewport({
                          activeMap, blip, waypoint, selectedIndex,
                        })}
                      </Stack.Item>
                      <Stack.Item className="Minimap__Legend">
                        {legendEntries.length === 0 && (
                          <Box color="label">Nothing explored yet.</Box>
                        )}
                        {legendEntries.map(({ color, areaName }) => (
                          <Stack key={color} className="Minimap__LegendRow">
                            <Stack.Item>
                              <Box
                                className="Minimap__Swatch"
                                style={{ 'background-color': color }} />
                            </Stack.Item>
                            <Stack.Item grow>{areaName}</Stack.Item>
                          </Stack>
                        ))}
                      </Stack.Item>
                    </Stack>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          </Stack>
        </Window.Content>
      </Window>
    );
  }
}
