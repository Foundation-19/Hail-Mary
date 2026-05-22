import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, Input } from '../components';
import { Window } from '../layouts';

type BountyBoardData = {
  active_bounties: Bounty[];
  available_contracts: Contract[];
  bounty_pool: number;
  is_officer: boolean;
  can_post: boolean;
  current_mark: string | null;
  bounties_posted: number;
  has_active_contract: boolean;
};

type Bounty = {
  bounty_id: number;
  target_ckey: string;
  target_name: string;
  amount: number;
  reason: string;
  placed_by_ckey: string;
  placed_by_name: string;
  faction_restriction: string;
  placed_at: string;
  expires_at: string;
  status: string;
};

type Contract = {
  id: string;
  name: string;
  description: string;
  reward: number;
  location_hint: string;
  difficulty: number;
  target_type: string;
  status: string;
  accepted_by: string;
};

const difficultyStars = (level: number): string => {
  return '★'.repeat(level) + '☆'.repeat(5 - level);
};

export const BountyBoard = (props, context) => {
  const { act, data } = useBackend<BountyBoardData>(context);
  const {
    active_bounties = [],
    available_contracts = [],
    is_officer,
    can_post,
    current_mark,
    bounties_posted,
    has_active_contract,
  } = data;

  const [targetCkey, setTargetCkey] = useLocalState(context, 'targetCkey', '');
  const [amount, setAmount] = useLocalState(context, 'amount', 100);
  const [reason, setReason] = useLocalState(context, 'reason', '');

  return (
    <Window width={700} height={600} title="NCR BOUNTY BOARD" theme="ncr">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          NEW CALIFORNIA REPUBLIC
          <span style={{ float: 'right' }}>BOUNTY DIVISION</span>
        </Box>

        <Section title="> ACTIVE BOUNTIES">
          {active_bounties.length > 0 ? (
            active_bounties.map((bounty) => (
              <Box
                key={bounty.bounty_id}
                style={{
                  border: '1px solid #2d5a87',
                  padding: '12px',
                  margin: '8px 0',
                  background: '#0a0f1a',
                }}
              >
                <Flex justify="space-between" align="center">
                  <Flex.Item>
                    <Box
                      style={{
                        color: '#ffd700',
                        fontWeight: 'bold',
                        fontSize: '1.2em',
                      }}
                    >
                      {bounty.target_name.toUpperCase()}
                    </Box>
                    <Box style={{ color: '#b8d4f0', marginTop: '5px' }}>
                      {bounty.amount} CAPS
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    {current_mark === bounty.target_ckey ? (
                      <Button content="[MARKED]" color="good" />
                    ) : (
                      <Button
                        content="[MARK]"
                        onClick={() => act('mark_target', {
                          target_ckey: bounty.target_ckey,
                        })}
                      />
                    )}
                    <Button
                      content="[CLAIM]"
                      onClick={() => act('claim_bounty', {
                        target_ckey: bounty.target_ckey,
                      })}
                    />
                  </Flex.Item>
                </Flex>
                <Box
                  style={{
                    color: '#4a90d9',
                    marginTop: '8px',
                    fontSize: '0.9em',
                  }}
                >
                  Reason: {bounty.reason}
                </Box>
                <Box style={{ color: '#666', marginTop: '5px', fontSize: '0.85em' }}>
                  Posted by: {bounty.placed_by_name}
                </Box>
              </Box>
            ))
          ) : (
            <Box
              style={{
                textAlign: 'center',
                padding: '20px',
                color: '#2a5a87',
              }}
            >
              No active bounties at this time.
            </Box>
          )}
        </Section>

        <Section title="> NCR CONTRACTS">
          {has_active_contract && (
            <Box
              style={{
                background: '#1a3a1a',
                border: '1px solid #44ff44',
                padding: '10px',
                marginBottom: '10px',
              }}
            >
              <Box style={{ color: '#44ff44' }}>
                You have an active contract. Complete it
                before accepting another.
              </Box>
            </Box>
          )}
          <Button
            content="[REFRESH CONTRACTS]"
            onClick={() => act('refresh_contracts')}
            style={{ marginBottom: '10px' }}
          />
          {available_contracts.map((contract) => (
            <Box
              key={contract.id}
              style={{
                border: '1px solid #2d5a87',
                padding: '12px',
                margin: '8px 0',
                background: contract.status === 'accepted' ? '#1a2a3a' : '#0a0f1a',
              }}
            >
              <Flex justify="space-between" align="flex-start">
                <Flex.Item grow={1}>
                  <Box style={{ color: '#ff6666', fontWeight: 'bold' }}>
                    [WANTED] {contract.name}
                  </Box>
                  <Box
                    style={{
                      color: '#b8d4f0',
                      marginTop: '5px',
                      fontSize: '0.9em',
                    }}
                  >
                    {contract.description}
                  </Box>
                  <Box style={{ marginTop: '8px' }}>
                    <Box style={{ color: '#ffd700' }}>
                      Reward: {contract.reward} caps
                    </Box>
                    <Box style={{ color: '#4a90d9' }}>
                      Location: {contract.location_hint}
                    </Box>
                    <Box style={{ color: '#888' }}>
                      Difficulty: {difficultyStars(contract.difficulty)}
                    </Box>
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  {contract.status === 'available' ? (
                    <Button
                      content="[ACCEPT]"
                      color={has_active_contract ? 'grey' : 'good'}
                      disabled={has_active_contract}
                      onClick={() => act('accept_contract', {
                        contract_id: contract.id,
                      })}
                    />
                  ) : (
                    <>
                      <Box style={{ color: '#4cff4c' }}>ACCEPTED</Box>
                      {contract.accepted_by && (
                        <Button
                          content="[COMPLETE]"
                          color="good"
                          onClick={() => act('complete_contract', {
                            contract_id: contract.id,
                          })}
                        />
                      )}
                    </>
                  )}
                </Flex.Item>
              </Flex>
            </Box>
          ))}
        </Section>

        {is_officer && (
          <Section title="> POST NEW BOUNTY">
            {!can_post ? (
              <Box style={{ color: '#ff4444' }}>
                {bounties_posted >= 3
                  ? 'Maximum active bounties reached (3).'
                  : 'Cooldown active. Please wait before posting another bounty.'}
              </Box>
            ) : (
              <>
                <Flex style={{ marginBottom: '10px' }}>
                  <Flex.Item grow={1} style={{ marginRight: '10px' }}>
                    <Box style={{ color: '#b8d4f0', marginBottom: '5px' }}>
                      Target:
                    </Box>
                    <Input
                      fluid
                      placeholder="Enter player name or ckey..."
                      value={targetCkey}
                      onInput={(e, value) => setTargetCkey(value)}
                    />
                  </Flex.Item>
                  <Flex.Item style={{ width: '100px' }}>
                    <Box style={{ color: '#b8d4f0', marginBottom: '5px' }}>
                      Amount (caps):
                    </Box>
                    <Input
                      fluid
                      value={amount}
                      onInput={(e, value) => setAmount(value)}
                    />
                  </Flex.Item>
                </Flex>
                <Box style={{ marginBottom: '10px' }}>
                  <Box style={{ color: '#b8d4f0', marginBottom: '5px' }}>
                    Reason:
                  </Box>
                  <Input
                    fluid
                    placeholder="Enter reason for bounty..."
                    value={reason}
                    onInput={(e, value) => setReason(value)}
                  />
                </Box>
                <Box style={{ color: '#666', marginBottom: '10px', fontSize: '0.85em' }}>
                  Min: 50 caps | Max: 500 caps | Expires after 7 days
                </Box>
                <Button
                  content="[POST BOUNTY]"
                  color="good"
                  onClick={() => {
                    act('post_bounty', {
                      target_ckey: targetCkey,
                      amount: amount,
                      reason: reason,
                    });
                    setTargetCkey('');
                    setReason('');
                  }}
                />
              </>
            )}
          </Section>
        )}

        {current_mark && (
          <Section title="> TRACKING">
            <Box style={{ color: '#4cff4c', marginBottom: '10px' }}>
              Currently tracking: {current_mark}
            </Box>
            <Button
              content="[CLEAR MARK]"
              color="bad"
              onClick={() => act('clear_mark')}
            />
          </Section>
        )}

        <Box className="CharacterSetup__footer">
          NEW CALIFORNIA REPUBLIC - BOUNTY DIVISION
        </Box>
      </Window.Content>
    </Window>
  );
};
