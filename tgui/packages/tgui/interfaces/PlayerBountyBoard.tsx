import { useBackend, useLocalState } from '../backend';
import { Box, Button, Input, LabeledList, NumberInput, Section, Table, Tabs } from '../components';
import { Window } from '../layouts';

type TargetRow = {
  ckey: string;
  name: string;
};

type BountyRow = {
  id: string;
  target_name: string;
  target_ckey: string;
  requester_name: string;
  requester_ckey: string;
  reward_caps: number;
  mode: string;
  notes: string;
  status: string;
  claimer_name: string;
  age_s: number;
  expires_s: number;
  can_claim: boolean;
  can_cancel: boolean;
};

type Data = {
  escrow_caps: number;
  user_ckey: string;
  min_reward_caps: number;
  max_reward_caps: number;
  default_expire_minutes: number;
  open_count: number;
  max_open_contracts: number;
  open_rows: BountyRow[];
  my_rows: BountyRow[];
  history_rows: BountyRow[];
  online_targets: TargetRow[];
};

export const PlayerBountyBoard = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const [tab, setTab] = useLocalState(context, 'pb_tab', 'Post');

  const [targetCkey, setTargetCkey] = useLocalState(context, 'pb_target_ckey', '');
  const [targetName, setTargetName] = useLocalState(context, 'pb_target_name', '');
  const [notes, setNotes] = useLocalState(context, 'pb_notes', '');
  const [rewardCaps, setRewardCaps] = useLocalState(context, 'pb_reward', 500);
  const [expireMinutes, setExpireMinutes] = useLocalState(context, 'pb_expire', data?.default_expire_minutes || 45);
  const [mode, setMode] = useLocalState(context, 'pb_mode', 'dead_or_alive');
  const [withdrawAmount, setWithdrawAmount] = useLocalState(context, 'pb_withdraw', 500);

  const postDisabled =
    rewardCaps < (data?.min_reward_caps || 0) ||
    rewardCaps > (data?.max_reward_caps || 999999);

  return (
    <Window width={960} height={700}>
      <Window.Content scrollable>
        <Section title="Player Bounty Board">
          <LabeledList>
            <LabeledList.Item label="Escrow Wallet">{data?.escrow_caps || 0} caps</LabeledList.Item>
            <LabeledList.Item label="Open Contracts">
              {data?.open_count || 0}/{data?.max_open_contracts || 0}
            </LabeledList.Item>
            <LabeledList.Item label="How To Deposit">
              Hit this machine with caps, NCR dollars, denarius, or aureus stacks.
            </LabeledList.Item>
          </LabeledList>
          <Box mt={1}>
            <NumberInput
              value={withdrawAmount}
              minValue={1}
              maxValue={Math.max(1, data?.escrow_caps || 1)}
              onChange={(_, value) => setWithdrawAmount(value)}
            />
            <Button ml={1} onClick={() => act('withdraw_escrow', { amount: withdrawAmount })}>
              Withdraw Amount
            </Button>
            <Button ml={1} onClick={() => act('withdraw_escrow', { all: 1 })}>
              Withdraw All
            </Button>
          </Box>
        </Section>

        <Tabs>
          <Tabs.Tab selected={tab === 'Post'} onClick={() => setTab('Post')}>
            Post
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Open'} onClick={() => setTab('Open')}>
            Open
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'My'} onClick={() => setTab('My')}>
            My Bounties
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'History'} onClick={() => setTab('History')}>
            History
          </Tabs.Tab>
        </Tabs>

        {tab === 'Post' && (
          <Section title="Post New Bounty (Escrowed)">
            <LabeledList>
              <LabeledList.Item label="Target Name">
                <Input
                  fluid
                  value={targetName}
                  placeholder="Target display name"
                  onChange={(_, value) => setTargetName(value)}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Target CKey (optional)">
                <Input
                  fluid
                  value={targetCkey}
                  placeholder="Exact ckey (best anti-fraud)"
                  onChange={(_, value) => setTargetCkey(value)}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Reward Caps">
                <NumberInput
                  value={rewardCaps}
                  minValue={data?.min_reward_caps || 100}
                  maxValue={data?.max_reward_caps || 50000}
                  onChange={(_, value) => setRewardCaps(value)}
                />
                <Box ml={1} color={postDisabled ? 'bad' : 'good'}>
                  Min {data?.min_reward_caps || 100}, Max {data?.max_reward_caps || 50000}
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Expiry (minutes)">
                <NumberInput
                  value={expireMinutes}
                  minValue={10}
                  maxValue={240}
                  onChange={(_, value) => setExpireMinutes(value)}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Mode">
                <Button selected={mode === 'alive'} onClick={() => setMode('alive')}>
                  Alive Only
                </Button>
                <Button selected={mode === 'dead'} onClick={() => setMode('dead')}>
                  Dead Only
                </Button>
                <Button selected={mode === 'dead_or_alive'} onClick={() => setMode('dead_or_alive')}>
                  Dead or Alive
                </Button>
              </LabeledList.Item>
              <LabeledList.Item label="Notes">
                <Input
                  fluid
                  value={notes}
                  placeholder="Reason, warning, wanted crimes, etc."
                  onChange={(_, value) => setNotes(value)}
                />
              </LabeledList.Item>
            </LabeledList>
            <Box mt={1}>
              <Button
                color="good"
                disabled={postDisabled}
                onClick={() =>
                  act('post_bounty', {
                    target_ckey: targetCkey,
                    target_name: targetName,
                    notes,
                    reward_caps: rewardCaps,
                    mode,
                    expire_minutes: expireMinutes,
                  })
                }>
                Post Escrowed Bounty
              </Button>
            </Box>
            <Section title="Online Targets (Quick Fill)" mt={1}>
              {!(data?.online_targets && data.online_targets.length) ? (
                <Box color="average">No eligible online targets right now.</Box>
              ) : (
                <Table>
                  <Table.Row header>
                    <Table.Cell>Name</Table.Cell>
                    <Table.Cell>CKey</Table.Cell>
                    <Table.Cell>Action</Table.Cell>
                  </Table.Row>
                  {(data.online_targets || []).map((t) => (
                    <Table.Row key={t.ckey}>
                      <Table.Cell>{t.name}</Table.Cell>
                      <Table.Cell>{t.ckey}</Table.Cell>
                      <Table.Cell>
                        <Button
                          onClick={() => {
                            setTargetCkey(t.ckey);
                            setTargetName(t.name);
                          }}>
                          Select
                        </Button>
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          </Section>
        )}

        {tab === 'Open' && (
          <Section title="Open Bounties">
            {!(data?.open_rows && data.open_rows.length) ? (
              <Box color="average">No open bounties.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>ID</Table.Cell>
                  <Table.Cell>Target</Table.Cell>
                  <Table.Cell>Poster</Table.Cell>
                  <Table.Cell>Mode</Table.Cell>
                  <Table.Cell>Reward</Table.Cell>
                  <Table.Cell>Expires</Table.Cell>
                  <Table.Cell>Notes</Table.Cell>
                  <Table.Cell>Action</Table.Cell>
                </Table.Row>
                {(data.open_rows || []).map((r) => (
                  <Table.Row key={r.id}>
                    <Table.Cell>{r.id}</Table.Cell>
                    <Table.Cell>{r.target_name}{r.target_ckey ? ` (${r.target_ckey})` : ''}</Table.Cell>
                    <Table.Cell>{r.requester_name}</Table.Cell>
                    <Table.Cell>{r.mode}</Table.Cell>
                    <Table.Cell>{r.reward_caps}</Table.Cell>
                    <Table.Cell>{r.expires_s}s</Table.Cell>
                    <Table.Cell>{r.notes || '-'}</Table.Cell>
                    <Table.Cell>
                      <Button disabled={!r.can_claim} onClick={() => act('claim_bounty', { id: r.id })}>
                        Claim
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
            <Box mt={1} color="average">
              Dead claims require the target corpse next to the board. Alive claims require the target restrained or buckled next to the board.
            </Box>
          </Section>
        )}

        {tab === 'My' && (
          <Section title="My Posted Bounties">
            {!(data?.my_rows && data.my_rows.length) ? (
              <Box color="average">You have not posted any bounties.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>ID</Table.Cell>
                  <Table.Cell>Target</Table.Cell>
                  <Table.Cell>Status</Table.Cell>
                  <Table.Cell>Reward</Table.Cell>
                  <Table.Cell>Expires</Table.Cell>
                  <Table.Cell>Action</Table.Cell>
                </Table.Row>
                {(data.my_rows || []).map((r) => (
                  <Table.Row key={r.id}>
                    <Table.Cell>{r.id}</Table.Cell>
                    <Table.Cell>{r.target_name}</Table.Cell>
                    <Table.Cell>{r.status}</Table.Cell>
                    <Table.Cell>{r.reward_caps}</Table.Cell>
                    <Table.Cell>{r.status === 'open' ? `${r.expires_s}s` : '-'}</Table.Cell>
                    <Table.Cell>
                      <Button disabled={!r.can_cancel} onClick={() => act('cancel_bounty', { id: r.id })}>
                        Cancel
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}

        {tab === 'History' && (
          <Section title="Resolved History">
            {!(data?.history_rows && data.history_rows.length) ? (
              <Box color="average">No resolved bounties yet.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>ID</Table.Cell>
                  <Table.Cell>Target</Table.Cell>
                  <Table.Cell>Status</Table.Cell>
                  <Table.Cell>Reward</Table.Cell>
                  <Table.Cell>Claimed By</Table.Cell>
                </Table.Row>
                {(data.history_rows || []).map((r) => (
                  <Table.Row key={r.id}>
                    <Table.Cell>{r.id}</Table.Cell>
                    <Table.Cell>{r.target_name}</Table.Cell>
                    <Table.Cell>{r.status}</Table.Cell>
                    <Table.Cell>{r.reward_caps}</Table.Cell>
                    <Table.Cell>{r.claimer_name || '-'}</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

export default PlayerBountyBoard;
