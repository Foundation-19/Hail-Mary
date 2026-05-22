import { useBackend, useLocalState } from '../backend';
import { Button, Section, Table, Stack, NoticeBox, Tabs, Flex, Box } from '../components';
import { Window } from '../layouts';

type TownHallData = {
  is_citizen?: boolean;
  is_council_member?: boolean;
  is_mayor?: boolean;
  election_active?: boolean;
  term_end_time?: number;
  citizens?: Citizen[];
  council?: CouncilMember[];
  candidates?: Candidate[];
  proposed_laws?: Law[];
  enacted_laws?: Law[];
};

type Citizen = {
  ckey?: string;
  name?: string;
};

type CouncilMember = {
  ckey?: string;
  name?: string;
  votes?: number;
  is_mayor?: boolean;
};

type Candidate = {
  ckey?: string;
  name?: string;
};

type Law = {
  id?: string;
  name?: string;
  description?: string;
  votes_for?: number;
  votes_against?: number;
};

export const TownHall = (props, context) => {
  const { act, data } = useBackend<TownHallData>(context);

  const {
    is_citizen,
    is_council_member,
    is_mayor,
    election_active,
    term_end_time,
    citizens = [],
    council = [],
    candidates = [],
    proposed_laws = [],
    enacted_laws = [],
  } = data;

  const [tab, setTab] = useLocalState(context, 'tab', 1);

  return (
    <Window theme="fallout" width={600} height={700}>
      <Window.Content scrollable>
        <Stack vertical>
          <Tabs>
            <Tabs.Tab selected={tab === 1} onClick={() => setTab(1)}>
              Citizenship
            </Tabs.Tab>
            <Tabs.Tab selected={tab === 2} onClick={() => setTab(2)}>
              Council
            </Tabs.Tab>
            <Tabs.Tab selected={tab === 3} onClick={() => setTab(3)}>
              Elections
            </Tabs.Tab>
            <Tabs.Tab selected={tab === 4} onClick={() => setTab(4)}>
              Laws
            </Tabs.Tab>
          </Tabs>

          {tab === 1 && (
            <Section title="Citizenship">
              {!is_citizen ? (
                <Button onClick={() => act('apply_citizenship')}>
                  Apply for Citizenship
                </Button>
              ) : (
                <NoticeBox success>You are a citizen of Eastwood.</NoticeBox>
              )}
              <Section title="Citizen Registry" level>
                <Table>
                  <Table.Row header>
                    <Table.Cell>Name</Table.Cell>
                    <Table.Cell>CKEY</Table.Cell>
                  </Table.Row>
                  {citizens.map(citizen => (
                    <Table.Row key={citizen.ckey}>
                      <Table.Cell>{citizen.name}</Table.Cell>
                      <Table.Cell>{citizen.ckey}</Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            </Section>
          )}

          {tab === 2 && (
            <Section title="Town Council">
              {is_council_member && (
                <NoticeBox info>You are a council member.</NoticeBox>
              )}
              {is_mayor && (
                <NoticeBox success>You are the Mayor!</NoticeBox>
              )}
              <Table>
                <Table.Row header>
                  <Table.Cell>Name</Table.Cell>
                  <Table.Cell>Votes</Table.Cell>
                  <Table.Cell>Role</Table.Cell>
                </Table.Row>
                {council.map(member => (
                  <Table.Row key={member.ckey}>
                    <Table.Cell>{member.name}</Table.Cell>
                    <Table.Cell>{member.votes}</Table.Cell>
                    <Table.Cell>{member.is_mayor ? 'Mayor' : 'Councilor'}</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          )}

          {tab === 3 && (
            <Section title="Elections">
              {election_active ? (
                <NoticeBox warning>Election in progress!</NoticeBox>
              ) : (
                <NoticeBox>No active election.</NoticeBox>
              )}
              {is_council_member && (
                <Button onClick={() => act('start_election')}>
                  Start Election
                </Button>
              )}
              {election_active && is_council_member && (
                <Button onClick={() => act('end_election')}>
                  End Election
                </Button>
              )}
              <Section title="Candidates" level>
                {!election_active && is_citizen && (
                  <Button onClick={() => act('register_candidate')}>
                    Register as Candidate
                  </Button>
                )}
                <Table>
                  <Table.Row header>
                    <Table.Cell>Name</Table.Cell>
                    <Table.Cell>Actions</Table.Cell>
                  </Table.Row>
                  {candidates.map(candidate => (
                    <Table.Row key={candidate.ckey}>
                      <Table.Cell>{candidate.name}</Table.Cell>
                      <Table.Cell>
                        {election_active && (
                          <Button onClick={() => act('cast_vote', { candidate: candidate.ckey })}>
                            Vote
                          </Button>
                        )}
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            </Section>
          )}

          {tab === 4 && (
            <Section title="Town Laws">
              {is_council_member && (
                <Button onClick={() => act('propose_law')}>
                  Propose New Law
                </Button>
              )}
              <Section title="Proposed Laws" level>
                {proposed_laws.map(law => (
                  <Section key={law.id} title={law.name} level>
                    <Box mb={1}>{law.description}</Box>
                    <Box mb={1}>
                      Votes: {law.votes_for} For / {law.votes_against} Against
                    </Box>
                    {is_council_member && (
                      <Flex gap={1}>
                        <Button onClick={() => act('vote_law', { law_id: law.id, vote: 1 })}>
                          Vote For
                        </Button>
                        <Button onClick={() => act('vote_law', { law_id: law.id, vote: 0 })}>
                          Vote Against
                        </Button>
                      </Flex>
                    )}
                  </Section>
                ))}
              </Section>
              <Section title="Enacted Laws" level>
                {enacted_laws.map(law => (
                  <Section key={law.id} title={law.name} level>
                    <Box>{law.description}</Box>
                  </Section>
                ))}
              </Section>
            </Section>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
