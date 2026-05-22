import { useBackend } from '../backend';
import { Box, Button, Section, Flex, Divider } from '../components';
import { Window } from '../layouts';

type KarmaHistoryData = {
  history: KarmaEntry[];
};

type KarmaEntry = {
  action: string;
  amount: number;
  before: number;
  after: number;
  reason: string;
  time: string;
};

export const KarmaHistory = (props, context) => {
  const { act, data } = useBackend<KarmaHistoryData>(context);
  const {
    history = [],
  } = data;

  return (
    <Window width={600} height={500} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
          <span style={{ float: 'right' }}>VAULT-TEC CORP</span>
        </Box>

        <Section title="> KARMA HISTORY">
          {history.length > 0 ? (
            history.map((entry, i) => (
              <Box
                key={i}
                style={{
                  border: '1px solid #1a5e38',
                  padding: '10px',
                  margin: '6px 0',
                  background: '#041a0e',
                }}
              >
                <Flex justify="space-between">
                  <Flex.Item style={{ color: '#4cff4c', fontWeight: 'bold' }}>{entry.action}</Flex.Item>
                  <Flex.Item style={{ color: entry.amount > 0 ? '#4cff4c' : '#ff3333' }}>
                    {entry.amount > 0 ? '+' : ''}{entry.amount}
                  </Flex.Item>
                </Flex>
                <Box style={{ color: '#888', fontSize: '0.9em', marginTop: '5px' }}>{entry.reason}</Box>
                <Box style={{ color: '#2a7a52', fontSize: '0.85em', marginTop: '3px' }}>
                  {entry.before} → {entry.after} | {entry.time}
                </Box>
              </Box>
            ))
          ) : (
            <Box style={{ color: '#2a7a52', textAlign: 'center', padding: '20px' }}>
              No karma history yet.
            </Box>
          )}
        </Section>

        <Box className="CharacterSetup__footer">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>
      </Window.Content>
    </Window>
  );
};
