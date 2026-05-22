import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex } from '../components';
import { Window } from '../layouts';

type MercenaryBoardData = {
  available_contracts: MercContract[];
  active_contract: MercContract | null;
  player_reputation: number;
  can_take_contracts: boolean;
};

type MercContract = {
  contract_id: string;
  name: string;
  description: string;
  faction_employer: string;
  reward_caps: number;
  reward_reputation: number;
  difficulty: number;
  time_limit: number;
  required_reputation: number;
  status: string;
  assigned_to: string | null;
  location_hint: string;
  objectives_total: number;
  objectives_completed: number;
};

const difficultyStars = (level: number): string => {
  return '★'.repeat(level) + '☆'.repeat(5 - level);
};

const factionColor = (faction: string): string => {
  switch (faction) {
    case 'ncr':
      return '#4a90d9';
    case 'bos':
      return '#8b8b8b';
    case 'legion':
      return '#c41e3a';
    case 'enclave':
      return '#4cff4c';
    default:
      return '#ffd700';
  }
};

const factionLabel = (faction: string): string => {
  switch (faction) {
    case 'ncr':
      return 'NCR';
    case 'bos':
      return 'BROTHERHOOD';
    case 'legion':
      return 'LEGION';
    case 'enclave':
      return 'ENCLAVE';
    default:
      return 'NEUTRAL';
  }
};

export const MercenaryBoard = (props, context) => {
  const { act, data } = useBackend<MercenaryBoardData>(context);
  const {
    available_contracts = [],
    active_contract,
    player_reputation,
    can_take_contracts,
  } = data;

  return (
    <Window width={700} height={650} title="MERCENARY CONTRACT BOARD" theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          FREELANCE CONTRACTS
          <span style={{ float: 'right' }}>REPUTATION: {player_reputation}</span>
        </Box>

        {active_contract && (
          <Section title="> YOUR ACTIVE CONTRACT">
            <Box
              style={{
                border: '1px solid #4cff4c',
                padding: '12px',
                margin: '8px 0',
                background: '#0a1a0a',
              }}
            >
              <Flex justify="space-between" align="flex-start">
                <Flex.Item grow={1}>
                  <Box
                    style={{
                      color: factionColor(active_contract.faction_employer),
                      fontWeight: 'bold',
                    }}
                  >
                    [{factionLabel(active_contract.faction_employer)}]{' '}
                    {active_contract.name}
                  </Box>
                  <Box style={{ color: '#b8d4f0', marginTop: '5px', fontSize: '0.9em' }}>
                    {active_contract.description}
                  </Box>
                  <Box style={{ marginTop: '8px' }}>
                    <Box style={{ color: '#ffd700' }}>
                      Reward: {active_contract.reward_caps} caps |
                      +{active_contract.reward_reputation} rep
                    </Box>
                    <Box style={{ color: '#888' }}>
                      Difficulty: {difficultyStars(active_contract.difficulty)}
                    </Box>
                    {active_contract.time_limit > 0 && (
                      <Box style={{ color: '#ff6666' }}>
                        Time Limit:{' '}
                        {Math.floor(active_contract.time_limit / 60000)} min
                      </Box>
                    )}
                    {active_contract.objectives_total > 0 && (
                      <Box style={{ color: '#4cff4c' }}>
                        Objectives:{' '}
                        {active_contract.objectives_completed}/
                        {active_contract.objectives_total}
                      </Box>
                    )}
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Button
                    content="[COMPLETE]"
                    color="good"
                    onClick={() => act('complete_contract', {
                      contract_id: active_contract.contract_id,
                    })}
                  />
                  <Button
                    content="[ABANDON]"
                    color="bad"
                    onClick={() => act('abandon_contract', {
                      contract_id: active_contract.contract_id,
                    })}
                  />
                </Flex.Item>
              </Flex>
            </Box>
          </Section>
        )}

        <Section title="> AVAILABLE CONTRACTS">
          {!can_take_contracts && !active_contract && (
            <Box
              style={{
                background: '#1a1a0a',
                border: '1px solid #ffcc00',
                padding: '10px',
                marginBottom: '10px',
              }}
            >
              <Box style={{ color: '#ffcc00' }}>
                You already have an active contract elsewhere.
              </Box>
            </Box>
          )}
          {available_contracts.length > 0 ? (
            available_contracts.map((contract) => {
              const borderColor = factionColor(contract.faction_employer);
              return (
                <Box
                  key={contract.contract_id}
                  style={{
                    border: `1px solid ${borderColor}`,
                    padding: '12px',
                    margin: '8px 0',
                    background: '#0a0a0a',
                  }}
                >
                  <Flex justify="space-between" align="flex-start">
                    <Flex.Item grow={1}>
                      <Box
                        style={{
                          color: factionColor(contract.faction_employer),
                          fontWeight: 'bold',
                          fontSize: '1.1em',
                        }}
                      >
                        [{factionLabel(contract.faction_employer)}]{' '}
                        {contract.name}
                      </Box>
                      <Box style={{ color: '#b8d4f0', marginTop: '5px', fontSize: '0.9em' }}>
                        {contract.description}
                      </Box>
                      <Box style={{ marginTop: '8px' }}>
                        <Box style={{ color: '#ffd700' }}>
                          Reward: {contract.reward_caps} caps
                        </Box>
                        <Box style={{ color: '#4cff4c' }}>
                          +{contract.reward_reputation}{' '}
                          {factionLabel(contract.faction_employer)} rep
                        </Box>
                        <Box style={{ color: '#888' }}>
                          Difficulty: {difficultyStars(contract.difficulty)}
                        </Box>
                        {contract.required_reputation > 0 && (
                          <Box style={{ color: '#ff6666' }}>
                            Requires: {contract.required_reputation} reputation
                          </Box>
                        )}
                        <Box style={{ color: '#4a90d9' }}>
                          Location: {contract.location_hint}
                        </Box>
                      </Box>
                    </Flex.Item>
                    <Flex.Item>
                      <Button
                        content="[ACCEPT]"
                        color={can_take_contracts ? 'good' : 'grey'}
                        disabled={!can_take_contracts}
                        onClick={() => act('accept_contract', {
                          contract_id: contract.contract_id,
                        })}
                      />
                    </Flex.Item>
                  </Flex>
                </Box>
              );
            })
          ) : (
            <Box
              style={{
                textAlign: 'center',
                padding: '20px',
                color: '#666',
              }}
            >
              No contracts available at this time. Check back later.
            </Box>
          )}
        </Section>

        <Section title="> CONTRACT INFORMATION">
          <Box style={{ color: '#888', fontSize: '0.9em' }}>
            <Box>
              &gt; Complete contracts to earn caps and reputation with factions.
            </Box>
            <Box>
              &gt; Higher reputation unlocks more difficult contracts.
            </Box>
            <Box>
              &gt; Abandoning contracts may harm your reputation.
            </Box>
            <Box>
              &gt; You can only have one active contract at a time.
            </Box>
          </Box>
        </Section>

        <Box className="CharacterSetup__footer">
          WASTELAND FREELANCE OPERATIONS
        </Box>
      </Window.Content>
    </Window>
  );
};
