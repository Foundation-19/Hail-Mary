import { useBackend } from '../backend';
import { Box, Button, Section, Flex, ProgressBar } from '../components';
import { Window } from '../layouts';

type GameModeData = {
  mode_name: string;
  threat_level: number;
  current_threat: number;
  storyteller_name: string;
  peaceful_percentage: number;
  forced_extended: boolean;
  classic_secret: boolean;
  no_stacking: boolean;
  stacking_limit: number;
  curve_centre: number;
  curve_width: number;
  executed_rules: string[];
  latejoin_timer: string;
  midround_timer: string;
};

export const GameModePanel = (props, context) => {
  const { act, data } = useBackend<GameModeData>(context);
  const {
    mode_name = 'Dynamic',
    threat_level = 0,
    current_threat = 0,
    storyteller_name = 'Unknown',
    peaceful_percentage = 50,
    forced_extended = false,
    classic_secret = false,
    no_stacking = false,
    stacking_limit = 3,
    curve_centre = 50,
    curve_width = 25,
    executed_rules = [],
    latejoin_timer = '0 seconds',
    midround_timer = '0 seconds',
  } = data;

  return (
    <Window width={450} height={550} title="GAME MODE PANEL" theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>

        <Section title="> MODE STATUS">
          <Flex align="center" mb={1}>
            <Flex.Item grow style={{ color: '#4cff4c', fontWeight: 'bold' }}>
              {mode_name}
            </Flex.Item>
            <Button
              compact
              content="[VV]"
              onClick={() => act('vv_mode')}
            />
            <Button
              compact
              content="[REFRESH]"
              onClick={() => act('refresh')}
            />
          </Flex>
        </Section>

        <Section title="> THREAT ANALYSIS">
          <Flex align="center" mb={1}>
            <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>TARGET:</Flex.Item>
            <Flex.Item grow>
              <ProgressBar
                value={threat_level}
                minValue={0}
                maxValue={100}
                color="#ffaa00"
              >
                <Box style={{ textAlign: 'center' }}>{threat_level}</Box>
              </ProgressBar>
            </Flex.Item>
          </Flex>

          <Flex align="center" mb={1}>
            <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>CURRENT:</Flex.Item>
            <Flex.Item grow>
              <ProgressBar
                value={current_threat}
                minValue={0}
                maxValue={100}
                color="#4cff4c"
              >
                <Box style={{ textAlign: 'center' }}>{current_threat}</Box>
              </ProgressBar>
            </Flex.Item>
            <Button compact content="[ADJUST]" onClick={() => act('adjust_threat')} />
            <Button compact content="[LOG]" onClick={() => act('view_log')} />
          </Flex>

          <Flex align="center" mb={1}>
            <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>STORYTELLER:</Flex.Item>
            <Flex.Item grow style={{ color: '#ffaa00' }}>
              {storyteller_name}
            </Flex.Item>
            <Button compact content="[CHANGE]" onClick={() => act('change_storyteller')} />
          </Flex>

          <Box style={{ color: '#2a7a52', fontSize: '11px', marginBottom: '8px' }}>
            PARAMETERS: centre = {curve_centre} ; width = {curve_width}
          </Box>
          <Box style={{ color: '#2a7a52', fontStyle: 'italic', fontSize: '11px' }}>
            On average, <span style={{ color: '#4cff4c' }}>{peaceful_percentage}%</span> of rounds are more peaceful.
          </Box>
        </Section>

        <Section title="> CONFIGURATION">
          <Flex align="center" mb={1}>
            <Flex.Item grow style={{ color: '#4cff4c' }}>FORCED EXTENDED:</Flex.Item>
            <Button
              content={forced_extended ? 'ON' : 'OFF'}
              selected={forced_extended}
              onClick={() => act('toggle_forced_extended')}
            />
          </Flex>

          <Flex align="center" mb={1}>
            <Flex.Item grow style={{ color: '#4cff4c' }}>CLASSIC SECRET:</Flex.Item>
            <Button
              content={classic_secret ? 'ON' : 'OFF'}
              selected={classic_secret}
              onClick={() => act('toggle_classic_secret')}
            />
          </Flex>

          <Flex align="center" mb={1}>
            <Flex.Item grow style={{ color: '#4cff4c' }}>NO STACKING:</Flex.Item>
            <Button
              content={no_stacking ? 'ON' : 'OFF'}
              selected={no_stacking}
              onClick={() => act('toggle_no_stacking')}
            />
          </Flex>

          <Flex align="center">
            <Flex.Item grow style={{ color: '#4cff4c' }}>STACKING LIMIT:</Flex.Item>
            <Box style={{ color: '#ffaa00', marginRight: '8px' }}>{stacking_limit}</Box>
            <Button compact content="[ADJUST]" onClick={() => act('adjust_stacking_limit')} />
          </Flex>
        </Section>

        <Section title="> EXECUTED RULESETS">
          {executed_rules.length > 0 ? (
            executed_rules.map((rule, i) => (
              <Box key={i} style={{ color: '#4cff4c', padding: '2px 0' }}>
                &gt; {rule}
              </Box>
            ))
          ) : (
            <Box style={{ color: '#2a7a52' }}>None executed.</Box>
          )}
        </Section>

        <Section title="> INJECTION TIMERS">
          <Flex align="center" mb={1}>
            <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>LATEJOIN:</Flex.Item>
            <Flex.Item grow style={{ color: '#ffaa00' }}>{latejoin_timer}</Flex.Item>
            <Button compact content="[NOW]" onClick={() => act('inject_latejoin')} />
          </Flex>

          <Flex align="center">
            <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>MIDROUND:</Flex.Item>
            <Flex.Item grow style={{ color: '#ffaa00' }}>{midround_timer}</Flex.Item>
            <Button compact content="[NOW]" onClick={() => act('inject_midround')} />
          </Flex>
        </Section>

        <Box className="CharacterSetup__footer">
          GAME MODE CONTROL | READY
        </Box>
      </Window.Content>
    </Window>
  );
};
