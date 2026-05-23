/**
 * Lockpicking.js — Semi-interactive lockpicking mini-game UI.
 *
 * Shows a set of lock pins. The player moves each pin up or down
 * and presses "Set Pin" to try to lock it at the correct height.
 * After a failed attempt each pin shows a heat indicator (direction
 * arrow + "One notch off!" / "Getting close" / "Way off") so the
 * player can narrow in over successive tries.
 */

import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

const TIER_LABELS = ['', 'Very Easy', 'Easy', 'Average', 'Hard', 'Very Hard'];

/** Returns display info for the heat indicator based on distance from zone. */
const hintInfo = (hint, lastDir) => {
  const arrow = lastDir > 0 ? '▲' : lastDir < 0 ? '▼' : '';
  if (hint < 0) return null; // no attempt yet
  if (hint === 1) return { color: '#ff5722', label: 'One notch off!', arrow };
  if (hint === 2) return { color: '#ff9800', label: 'Getting close', arrow };
  if (hint === 3) return { color: '#42a5f5', label: 'Not quite', arrow };
  return { color: '#1565c0', label: 'Way off', arrow };
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
    isMasterPick,
    totalPins,
  } = data;

  const isFinished = phase !== 'picking';
  const activePinIndex = pins.findIndex(p => p.active);
  const activePin = activePinIndex !== -1 ? pins[activePinIndex] : null;

  return (
    <Window
      theme="fallout"
      title="Lock Picking"
      width={500}
      height={520}>
      <Window.Content>

        {/* ── Status ───────────────────────────────────────── */}
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
                {luck} / 10{isMasterPick ? ' — Master Pick' : ''}
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
        </Section>

        {/* ── Feedback ─────────────────────────────────────── */}
        <NoticeBox
          success={phase === 'success'}
          danger={phase === 'failed'}>
          {feedback}
        </NoticeBox>

        {/* ── Pins ─────────────────────────────────────────── */}
        <Section title={`Pins — ${pinsSet} / ${totalPins} Set`}>
          <Box style={{ 'display': 'flex', 'justify-content': 'center', 'align-items': 'flex-start', 'flex-wrap': 'wrap' }}>
            {pins.map((pin, i) => {
              const heat = hintInfo(pin.hint, pin.lastDir);
              return (
                <Box
                  key={i}
                  mx="5px"
                  textAlign="center"
                  style={{
                    'border': pin.active
                      ? '1px solid #ffaa00'
                      : pin.set
                        ? '1px solid #00c853'
                        : '1px solid #333',
                    'border-radius': '4px',
                    'padding': '4px 4px 6px 4px',
                    'background': pin.active ? 'rgba(255,170,0,0.06)' : 'transparent',
                    'min-width': '48px',
                  }}>

                  {/* Pin label */}
                  <Box
                    mb="3px"
                    fontSize="11px"
                    bold
                    color={pin.set ? 'good' : pin.active ? 'yellow' : 'grey'}>
                    PIN {i + 1}
                  </Box>

                  {/* Segments — column-reverse so pos 1 = bottom */}
                  <Box style={{
                    'display': 'flex',
                    'flex-direction': 'column-reverse',
                    'align-items': 'center',
                    'gap': '2px',
                  }}>
                    {Array.from({ length: 10 }, (_, si) => {
                      const segPos = si + 1;
                      const isCurrent = !pin.set && pin.pos === segPos;
                      let bg;
                      if (pin.set) {
                        bg = '#00c853';
                      } else if (isCurrent && pin.active) {
                        bg = '#ffaa00';
                      } else if (isCurrent) {
                        bg = '#3a7abf';
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
                      <Box color="good" bold>✓</Box>
                    ) : pin.active ? (
                      <Box color="label">{pin.pos} / 10</Box>
                    ) : (
                      <Box color="grey">—</Box>
                    )}
                  </Box>

                  {/* Heat hint + tension warning — only shown on active pin */}
                  <Box style={{ 'min-height': '42px' }}>
                    {pin.active && heat && (
                      <Box mt="3px" fontSize="11px" color={heat.color} bold>
                        {heat.arrow} {heat.label}
                      </Box>
                    )}
                    {pin.active && tensionInfo(pin.tension) && (
                      <Box mt="2px" fontSize="10px" color={tensionInfo(pin.tension).color} bold>
                        ⚠ {tensionInfo(pin.tension).label}
                      </Box>
                    )}
                  </Box>
                </Box>
              );
            })}
          </Box>
        </Section>

        {/* ── Controls ─────────────────────────────────────── */}
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
              {phase === 'success' ? '— Lock Opened —' : '— Lock Picking Failed —'}
            </Box>
          </Section>
        )}

      </Window.Content>
    </Window>
  );
};
