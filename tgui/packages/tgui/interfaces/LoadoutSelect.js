import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Button, Flex, Tabs, Section } from '../components';

export const LoadoutSelect = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window width={640} height={560} resizable theme="fallout">
      <Window.Content>
        <Flex height="100%">
          {/* Left: vertical scrollable loadout list */}
          <Flex.Item
            style={{
              "width": "155px",
              "min-width": "155px",
              "overflow-y": "auto",
              "overflow-x": "hidden",
              "border-right": "1px solid #3ac83a",
            }}>
            <Tabs vertical fill style={{ "font-size": "15px" }}>
              {!(data.outfits?.length)
                ? <div style={{ "padding": "8px", "color": "#4aed92" }}>No loadout options.</div>
                : data.outfits.map(outfit => (
                  <Tabs.Tab
                    key={outfit}
                    selected={data.selected === outfit}
                    onClick={() => act('loadout_select', {
                      name: outfit,
                    })}>
                    {outfit}
                  </Tabs.Tab>
                ))}
            </Tabs>
          </Flex.Item>
          {/* Center: contents list */}
          <Flex.Item grow={1} style={{ "overflow-y": "auto" }}>
            <Section title="Contents" fill fitted>
              {!data.items?.length
                ? "No outfit selected."
                : data.items.map(item => (
                  <div style={{ "margin": "10px 10px", "text-align": "center" }} key={`${item.name}`}>
                    <div style={{ "transform": "scale(1.5)", "vertical-align": "middle", "float": "left", "clear": "left", "height": "32px", "width": "32px" }} class={item.icon} />
                    <div style={{ "display": "block", "vertical-align": "middle", "float": "left", "width": "calc(100% - 32px)", "line-height": "32px", "margin": "auto" }}>
                      {item.name}{' '}
                      {item.quantity > 1 && (`x${item.quantity}`)}<br />
                    </div>
                  </div>
                ))}
            </Section>
          </Flex.Item>
          {/* Right: preview */}
          <Flex.Item
            style={{
              "width": "240px",
              "min-width": "240px",
              "border-left": "1px solid #3ac83a",
            }}>
            <Section title="Preview" fill>
              {!data.preview
                ? "No outfit selected."
                : (
                  <div style={{ "text-align": "center" }}>
                    <img src={`data:image/jpeg;base64,${data.preview}`} style={{ "image-rendering": "pixelated", "-ms-interpolation-mode": "nearest-neighbor" }} width={220} height={220} /><br />
                    <br />
                    <div style={{ "display": "table", "width": "100%", "text-align": "center" }}>
                      <Button style={{ "display": "table-cell", "text-align": "center" }} content={"<<"} onClick={() => act('loadout_preview_direction', { direction: -1 })} />
                      <Button style={{ "display": "table-cell", "text-align": "center" }} content={">>"} onClick={() => act('loadout_preview_direction', { direction: 1 })} />
                    </div>
                    <Button style={{ "margin": "auto", "display": "block", "text-align": "center" }} content={"Finished"} onClick={() => act('loadout_confirm')} />
                  </div>
                )}
            </Section>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};
