/**
 * Lockpicking.js \u2014 Semi-interactive lockpicking mini-game UI.
 *
 * Shows a set of lock pins. The player moves each pin up or down
 * and presses "Set Pin" to try to lock it at the correct height.
 * After a failed attempt each pin shows a heat indicator (direction
 * arrow + hint detail scaled by Perception) so the player can
 * narrow in over successive tries.
 *
 * New features:
 *  - Non-linear pin selection: click any unset pin to focus it
 *  - Tried positions: previously failed positions shown in dim red
 *  - Perception-scaled hints: low PER = vague, high PER = exact range
 *  - Keyboard shortcuts: W/S/\u2191/\u2193 move, Space/Enter set,
 *    Escape give up, 1-5 select pin
 *  - Environmental penalty badges (darkness, injuries, gloves)
 */

import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

const TIER_LABELS = ['', 'Very Easy', 'Easy', 'Average', 'Hard', 'Very Hard'];

// CSS animation for the active pin glow pulse (injected via a <style> tag).
const PIN_PULSE_CSS = (
  '@keyframes lpPinPulse{'
  + '0%,100%{box-shadow:0 0 5px rgba(255,170,0,0.3);}'
  + '50%{box-shadow:0 0 10px rgba(255,170,0,0.8);}}'
);

// Module-level keyboard handler — Inferno v7 has no hooks,
// so we manage the listener directly (single-instance interface).
let _lpKeyHandler = null;

/**
 * Returns display info for the heat indicator.
 * Detail level scales with Perception (1-10):
 *   PER 1-3: direction only ("Off target")
 *   PER 4-6: category labels (current behaviour)
 *   PER 7-8: exact distance number
 *   PER 9-10: exact distance + estimated zone range text
 */
const hintInfo = (hint, lastDir, lastPos, perception) => {
  const arrow = lastDir > 0 ? '\u25B2' : lastDir < 0 ? '\u25BC' : '';
  if (hint < 0) return null; // no attempt yet

  const per = perception || 5;

  if (per <= 3) {
    // Very low PER \u2014 just a direction
    return { color: '#7986cb', label: 'Off target', arrow };
  }

  // Base label from distance (PER 4+)
  let color, label;
  if (hint === 1) { color = '#ff5722'; label = 'One notch off!'; }
  else if (hint === 2) { color = '#ff9800'; label = 'Getting close'; }
  else if (hint === 3) { color = '#42a5f5'; label = 'Not quite'; }
  else { color = '#1565c0'; label = 'Way off'; }

  if (per >= 7 && lastPos) {
    // High PER \u2014 show the estimated zone range
    let rangeText;
    if (lastDir > 0) {
      // too low: zone_min = lastPos + 1, zone_max = lastPos + hint
      const lo = lastPos + 1;
      const hi = lastPos + hint;
      rangeText = lo === hi ? `Try position ${lo}` : `Try ${lo}\u2013${hi}`;
    } else {
      // too high: zone_max = lastPos - 1, zone_min = lastPos - hint
      const hi = lastPos - 1;
      const lo = lastPos - hint;
      rangeText = lo === hi ? `Try position ${lo}` : `Try ${lo}\u2013${hi}`;
    }
    if (per >= 9) {
      label = rangeText;
    } else {
      label = `${label} (${rangeText})`;
    }
  }

  return { color, label, arrow };
};

/** Returns display info for pick tension (moves accumulated on current pin). */
const tensionInfo = (tension) => {
  if (!tension || tension <= 0) return null;
  if (tension <= 2) return { color: '#ffee58', label: 'Building...' };
  if (tension <= 4) return { color: '#ff9800', label: 'Careful!' };
  return { color: '#f44336', label: 'ABOUT TO SNAP!' };
};

export const Lockpicking = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    pins = [],
    pinsSet = 0,
    attemptsLeft,
    maxAttempts,
    phase,
    feedback,
    lockTier,
    luck,
    perception = 5,
    isMasterPick,
    totalPins,
    isDark,
    isHurt,
    wearingGloves,
  } = data;

  const isFinished = phase !== 'picking';
  const activePinIndex = pins.findIndex(p => p.active);
  const activePin = activePinIndex !== -1 ? pins[activePinIndex] : null;

  // Keyboard shortcuts — swap handler on each render so it closes
  // over the latest act/data values.
  if (_lpKeyHandler) {
    document.removeEventListener('keydown', _lpKeyHandler);
  }
  if (!isFinished) {
    _lpKeyHandler = (e) => {
      if (e.key === 'w' || e.key === 'W' || e.key === 'ArrowUp') {
        e.preventDefault();
        act('move_up');
      } else if (e.key === 's' || e.key === 'S' || e.key === 'ArrowDown') {
        e.preventDefault();
        act('move_down');
      } else if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        act('set_pin');
      } else if (e.key === 'Escape') {
        e.preventDefault();
        act('give_up');
      } else if (e.key >= '1' && e.key <= '5') {
        const idx = parseInt(e.key, 10);
        if (idx <= pins.length && !pins[idx - 1].set) {
          e.preventDefault();
          act('select_pin', { pin: idx });
        }
      }
    };
    document.addEventListener('keydown', _lpKeyHandler);
  } else {
    _lpKeyHandler = null;
  }

  return (
    <Window
      theme="fallout"
      title="Lock Picking"
      width={500}
      height={580}>
      <Window.Content>
        <style>{PIN_PULSE_CSS}</style>

        {/* Status */}
        <Section title="Lock Status">
          <LabeledList>
            <LabeledList.Item label="Difficulty">
              <ProgressBar
                value={lockTier}
                minValue={0}
                maxValue={5}
                ranges={{
                  good: [-Infinity, 1.5],
                  average: [1.5, 3.5],
                  bad: [3.5, Infinity],
                }}>
                {TIER_LABELS[lockTier] || 'Unknown'}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Luck">
              <ProgressBar
                value={luck}
                minValue={0}
                maxValue={10}
                ranges={{
                  bad: [-Infinity, 3],
                  average: [3, 6],
                  good: [6, Infinity],
                }}>
                {luck} / 10{isMasterPick ? ' \u2014 Master Pick' : ''}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Attempts Left">
              <ProgressBar
                value={attemptsLeft}
                minValue={0}
                maxValue={maxAttempts}
                ranges={{
                  bad: [-Infinity, 2],
                  average: [2, 4],
                  good: [4, Infinity],
                }}>
                {attemptsLeft} / {maxAttempts}
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>

          {/* Environmental penalty badges */}
          {!!(isDark || isHurt || wearingGloves) && (
            <Box mt="4px" style={{ 'display': 'flex', 'gap': '4px', 'flex-wrap': 'wrap' }}>
              {!!isDark && (
                <Box
                  fontSize="11px"
                  style={{
                    'background': '#1a1a2e',
                    'border': '1px solid #4a4a7a',
                    'border-radius': '3px',
                    'padding': '1px 5px',
                    'color': '#9090d0',
                  }}>
                  Darkness penalty
                </Box>
              )}
              {!!isHurt && (
                <Box
                  fontSize="11px"
                  style={{
                    'background': '#2e1a1a',
                    'border': '1px solid #7a2a2a',
                    'border-radius': '3px',
                    'padding': '1px 5px',
                    'color': '#d08080',
                  }}>
                  Injury penalty
                </Box>
              )}
              {!!wearingGloves && (
                <Box
                  fontSize="11px"
                  style={{
                    'background': '#1a2e1a',
                    'border': '1px solid #2a6a2a',
                    'border-radius': '3px',
                    'padding': '1px 5px',
                    'color': '#80c080',
                  }}>
                  Glove penalty
                </Box>
              )}
            </Box>
          )}
        </Section>

        {/* Feedback */}
        <NoticeBox
          success={phase === 'success'}
          danger={phase === 'failed'}>
          {feedback}
        </NoticeBox>

        {/* Pins */}
        <Section title={`Pins \u2014 ${pinsSet} / ${totalPins} Set`}>
          {!isFinished && (
            <Box
              mb="2px"
              fontSize="10px"
              color="label"
              textAlign="center">
              {'Click any unset pin. Keys: W/↑ up · S/↓ down · Space set · Esc give up · 1-5 select pin'}
            </Box>
          )}
          {!!activePin && !isFinished && (
            <Box mb="4px">
              <ProgressBar
                value={activePin.tension}
                minValue={0}
                maxValue={10}
                ranges={{
                  good: [-Infinity, 3],
                  average: [3, 6],
                  bad: [6, Infinity],
                }}>
                Pick tension: {activePin.tension} / 10
              </ProgressBar>
            </Box>
          )}
          <Box style={{ 'display': 'flex', 'justify-content': 'center', 'align-items': 'flex-start', 'flex-wrap': 'wrap' }}>
            {pins.map((pin, i) => {
              const heat = hintInfo(
                pin.hint, pin.lastDir, pin.lastPos, perception
              );
              const isClickable = !isFinished && !pin.active && !pin.set;
              return (
                <Box
                  key={i}
                  mx="5px"
                  textAlign="center"
                  onClick={isClickable ? () => act('select_pin', { pin: i + 1 }) : undefined}
                  style={{
                    'border': pin.active
                      ? '1px solid #ffaa00'
                      : pin.set
                        ? '1px solid #00c853'
                        : pin.security
                          ? '1px solid #7a2a0a'
                          : (pin.decayed && !pin.set)
                            ? '1px solid #5a3a00'
                            : '1px solid #333',
                    'border-radius': '4px',
                    'padding': '4px 4px 6px 4px',
                    'background': pin.active
                      ? 'rgba(255,170,0,0.06)'
                      : (pin.decayed && !pin.set)
                        ? 'rgba(90,58,0,0.12)'
                        : 'transparent',
                    'animation': pin.active ? 'lpPinPulse 1.5s ease-in-out infinite' : undefined,
                    'min-width': '48px',
                    'cursor': isClickable ? 'pointer' : 'default',
                  }}>

                  {/* Pin label */}
                  <Box
                    mb="3px"
                    fontSize="11px"
                    bold
                    color={pin.set ? 'good' : pin.active ? 'yellow' : 'grey'}>
                    PIN {i + 1}
                  </Box>
                  {!!pin.spool && !pin.set && (
                    <Box fontSize="9px" color="yellow" italic>spool</Box>
                  )}
                  {!!pin.security && !pin.set && (
                    <Box fontSize="9px" color="bad" italic>serrated</Box>
                  )}

                  {/* Segments \u2014 column-reverse so pos 1 = bottom */}
                  <Box style={{
                    'display': 'flex',
                    'flex-direction': 'column-reverse',
                    'align-items': 'center',
                    'gap': '1px',
                  }}>
                    {Array.from({ length: 10 }, (_, si) => {
                      const segPos = si + 1;
                      const isCurrent = !pin.set && pin.pos === segPos;
                      const wasTried = !pin.set
                        && pin.tried && pin.tried.includes(segPos);
                      let bg;
                      if (pin.set) {
                        bg = '#00c853';
                      } else if (isCurrent && pin.active) {
                        bg = '#ffaa00';
                      } else if (isCurrent) {
                        bg = '#1e3060'; // subtle: shows where pin is parked
                      } else if (wasTried) {
                        const th = pin.triedHints && pin.triedHints[segPos];
                        if (th === 1) bg = '#7a2a0a'; // hot: one off
                        else if (th === 2) bg = '#5a3a00'; // warm: two off
                        else if (th === 3) bg = '#1e2a4a'; // cool: three off
                        else bg = '#1a1a3a'; // cold: far away
                      } else {
                        bg = '#1e1e1e';
                      }
                      return (
                        <Box
                          key={si}
                          style={{
                            'width': '34px',
                            'height': '11px',
                            'background-color': bg,
                            'border': isCurrent && pin.active
                              ? '1px solid #ffcc00'
                              : wasTried
                                ? '1px solid #5a2a2a'
                                : '1px solid #2e2e2e',
                            'border-radius': '2px',
                          }}
                        />
                      );
                    })}
                  </Box>

                  {/* Position label */}
                  <Box mt="3px" fontSize="11px">
                    {pin.set ? (
                      <Box color="good" bold>{'✓'}</Box>
                    ) : pin.active ? (
                      <Box color="label">{pin.pos} / 10</Box>
                    ) : pin.decayed ? (
                      <Box color="average" bold>{'!'}</Box>
                    ) : (
                      <Box color="grey">{'—'}</Box>
                    )}
                  </Box>

                  {/* Heat hint (inactive pins show faded hint) */}
                  <Box style={{ 'min-height': '30px' }}>
                    {!!pin.active && heat && (
                      <Box mt="3px" fontSize="11px" color={heat.color} bold>
                        {heat.arrow} {heat.label}
                      </Box>
                    )}
                    {!pin.active && !pin.set && heat && (
                      <Box mt="3px" fontSize="10px" color="#555" italic>
                        {heat.arrow} {heat.label}
                      </Box>
                    )}
                  </Box>
                </Box>
              );
            })}
          </Box>
        </Section>

        {/* Controls */}
        {!isFinished && activePin !== null && (
          <Section>
            <Box textAlign="center">
              <Button
                icon="arrow-up"
                mr={1}
                onClick={() => act('move_up')}>
                Move Up
              </Button>
              <Button
                icon="arrow-down"
                mr={1}
                onClick={() => act('move_down')}>
                Move Down
              </Button>
              <Button
                icon="check"
                color="good"
                mr={1}
                onClick={() => act('set_pin')}>
                Set Pin
              </Button>
              <Button
                icon="times"
                color="bad"
                onClick={() => act('give_up')}>
                Give Up
              </Button>
            </Box>
          </Section>
        )}

        {isFinished && (
          <Section textAlign="center">
            <Box
              color={phase === 'success' ? 'good' : 'bad'}
              fontSize="14px"
              bold>
              {phase === 'success' ? '\u2014 Lock Opened \u2014' : '\u2014 Lock Picking Failed \u2014'}
            </Box>
          </Section>
        )}

      </Window.Content>
    </Window>
  );
};
