import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, Divider } from '../components';
import { Window } from '../layouts';

type QuestJournalData = {
  active_quests: QuestProgress[];
  completed_quests: QuestProgress[];
  available_quests: QuestInfo[];
  player_faction: string;
};

type QuestProgress = {
  id: string;
  name: string;
  description: string;
  status: string;
  progress: number;
};

type QuestInfo = {
  id: string;
  name: string;
  description: string;
  faction: string;
  caps: number;
  karma_type: string;
};

export const QuestJournal = (props, context) => {
  const { act, data } = useBackend<QuestJournalData>(context);
  const {
    active_quests = [],
    completed_quests = [],
    available_quests = [],
    player_faction = '',
  } = data;

  const [tab, setTab] = useLocalState(context, 'tab', 0);

  return (
    <Window width={700} height={600} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
          <span style={{ float: 'right' }}>VAULT-TEC CORP</span>
        </Box>

        <Section>
          <Flex>
            <Flex.Item grow>
              <Button
                fluid
                content="> ACTIVE"
                selected={tab === 0}
                onClick={() => setTab(0)}
              />
            </Flex.Item>
            <Flex.Item grow>
              <Button
                fluid
                content="> AVAILABLE"
                selected={tab === 1}
                onClick={() => setTab(1)}
              />
            </Flex.Item>
            <Flex.Item grow>
              <Button
                fluid
                content="> COMPLETED"
                selected={tab === 2}
                onClick={() => setTab(2)}
              />
            </Flex.Item>
          </Flex>
        </Section>

        {tab === 0 && (
          <Section title={`> ACTIVE QUESTS (${active_quests.length})`}>
            {active_quests.length > 0 ? (
              active_quests.map(quest => (
                <Box
                  key={quest.id}
                  style={{
                    border: '1px solid #1a5e38',
                    padding: '12px',
                    margin: '8px 0',
                    background: '#041a0e',
                  }}
                >
                  <Box style={{ color: '#ffaa00', fontWeight: 'bold', fontSize: '1.1em' }}>{quest.name}</Box>
                  <Box style={{ color: '#2a7a52', margin: '8px 0' }}>{quest.description}</Box>
                  <Box style={{ color: '#4cff4c' }}>Status: {quest.status}</Box>
                  <Button
                    content="[ABANDON]"
                    color="bad"
                    onClick={() => act('abandon', { quest: quest.id })}
                    style={{ marginTop: '8px' }}
                  />
                </Box>
              ))
            ) : (
              <Box style={{ color: '#2a7a52', textAlign: 'center', padding: '20px' }}>
                No active quests. Check Available for new quests!
              </Box>
            )}
          </Section>
        )}

        {tab === 1 && (
          <Section title={`> AVAILABLE QUESTS (${available_quests.length})`}>
            {available_quests.length > 0 ? (
              available_quests.map(quest => (
                <Box
                  key={quest.id}
                  style={{
                    border: '1px solid #1a5e38',
                    padding: '12px',
                    margin: '8px 0',
                    background: '#041a0e',
                  }}
                >
                  <Flex justify="space-between" align="flex-start">
                    <Flex.Item grow>
                      <Box style={{ color: '#4cff4c', fontWeight: 'bold' }}>{quest.name}</Box>
                      <Box style={{ color: '#2a7a52', margin: '8px 0', fontSize: '0.9em' }}>{quest.description}</Box>
                      {quest.caps > 0 && (
                        <Box style={{ color: '#ffaa00', fontSize: '0.9em' }}>Reward: {quest.caps} caps</Box>
                      )}
                      {quest.faction && (
                        <Box style={{ color: '#888', fontSize: '0.85em' }}>Faction: {quest.faction}</Box>
                      )}
                    </Flex.Item>
                    <Flex.Item>
                      <Button
                        content="[ACCEPT]"
                        color="good"
                        onClick={() => act('accept', { quest: quest.id })}
                      />
                    </Flex.Item>
                  </Flex>
                </Box>
              ))
            ) : (
              <Box style={{ color: '#2a7a52', textAlign: 'center', padding: '20px' }}>
                No quests available at this time.
              </Box>
            )}
          </Section>
        )}

        {tab === 2 && (
          <Section title={`> COMPLETED QUESTS (${completed_quests.length})`}>
            {completed_quests.length > 0 ? (
              completed_quests.map(quest => (
                <Box
                  key={quest.id}
                  style={{
                    border: '1px solid #2a4a2a',
                    padding: '12px',
                    margin: '8px 0',
                    background: '#061a0e',
                    opacity: 0.8,
                  }}
                >
                  <Box style={{ color: '#4cff4c', fontWeight: 'bold' }}>{quest.name}</Box>
                  <Box style={{ color: '#2a7a52', margin: '8px 0', fontSize: '0.9em' }}>{quest.description}</Box>
                  <Box style={{ color: '#888' }}>Completed</Box>
                </Box>
              ))
            ) : (
              <Box style={{ color: '#2a7a52', textAlign: 'center', padding: '20px' }}>
                No completed quests yet.
              </Box>
            )}
          </Section>
        )}

        <Box className="CharacterSetup__footer">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>
      </Window.Content>
    </Window>
  );
};
