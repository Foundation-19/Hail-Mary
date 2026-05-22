import { useBackend, useLocalState } from '../backend';
import { Button, Section, Table, Stack, NoticeBox, Input, Flex, Box } from '../components';
import { Window } from '../layouts';

type SheriffOfficeData = {
  is_sheriff?: boolean;
  is_deputy?: boolean;
  is_law_enforcement?: boolean;
  sheriff_name?: string;
  max_deputies?: number;
  deputies?: Deputy[];
  active_warrants?: Warrant[];
  outstanding_fines?: Fine[];
};

type Deputy = {
  ckey?: string;
  name?: string;
};

type Warrant = {
  target_ckey?: string;
  target_name?: string;
  crime?: string;
  issuer_ckey?: string;
};

type Fine = {
  target_ckey?: string;
  target_name?: string;
  amount?: number;
  reason?: string;
};

export const SheriffOffice = (props, context) => {
  const { act, data } = useBackend<SheriffOfficeData>(context);

  const {
    is_sheriff,
    is_deputy,
    is_law_enforcement,
    sheriff_name,
    max_deputies = 5,
    deputies = [],
    active_warrants = [],
    outstanding_fines = [],
  } = data;

  const [targetCkey, setTargetCkey] = useLocalState(context, 'target_ckey', '');
  const [crime, setCrime] = useLocalState(context, 'crime', '');
  const [fineAmount, setFineAmount] = useLocalState(context, 'fine_amount', 50);
  const [fineReason, setFineReason] = useLocalState(context, 'fine_reason', '');

  return (
    <Window theme="fallout" width={600} height={700}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="Sheriff's Office">
            {is_sheriff ? (
              <NoticeBox success>You are the Sheriff of Eastwood.</NoticeBox>
            ) : is_deputy ? (
              <NoticeBox info>You are a Deputy.</NoticeBox>
            ) : (
              <NoticeBox>You are not law enforcement.</NoticeBox>
            )}
            {sheriff_name && (
              <Box>Current Sheriff: <b>{sheriff_name}</b></Box>
            )}
          </Section>

          {is_sheriff && (
            <Section title={`Deputies (${deputies.length}/${max_deputies})`}>
              <Flex direction="column" gap="5px">
                <Input
                  value={targetCkey}
                  onInput={(e, value) => setTargetCkey(value)}
                  placeholder="Target CKEY"
                />
                <Button onClick={() => act('appoint_deputy', { target_ckey: targetCkey })}>
                  Appoint Deputy
                </Button>
              </Flex>
              <Table>
                <Table.Row header>
                  <Table.Cell>Name</Table.Cell>
                  <Table.Cell>Actions</Table.Cell>
                </Table.Row>
                {deputies.map(deputy => (
                  <Table.Row key={deputy.ckey}>
                    <Table.Cell>{deputy.name}</Table.Cell>
                    <Table.Cell>
                      <Button onClick={() => act('remove_deputy', { target_ckey: deputy.ckey })}>
                        Remove
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          )}

          {is_law_enforcement && (
            <>
              <Section title="Arrest Warrants">
                <Flex direction="column" gap="5px">
                  <Input
                    value={targetCkey}
                    onInput={(e, value) => setTargetCkey(value)}
                    placeholder="Target CKEY"
                  />
                  <Input
                    value={crime}
                    onInput={(e, value) => setCrime(value)}
                    placeholder="Crime"
                  />
                  <Button onClick={() => act('issue_warrant', { target_ckey: targetCkey, crime: crime })}>
                    Issue Warrant
                  </Button>
                </Flex>
                <Table>
                  <Table.Row header>
                    <Table.Cell>Name</Table.Cell>
                    <Table.Cell>Crime</Table.Cell>
                    <Table.Cell>Actions</Table.Cell>
                  </Table.Row>
                  {active_warrants.map(warrant => (
                    <Table.Row key={warrant.target_ckey}>
                      <Table.Cell>{warrant.target_name}</Table.Cell>
                      <Table.Cell>{warrant.crime}</Table.Cell>
                      <Table.Cell>
                        <Button onClick={() => act('clear_warrant', { target_ckey: warrant.target_ckey })}>
                          Clear
                        </Button>
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>

              <Section title="Issue Fines">
                <Flex direction="column" gap="5px">
                  <Input
                    value={targetCkey}
                    onInput={(e, value) => setTargetCkey(value)}
                    placeholder="Target CKEY"
                  />
                  <Input
                    value={fineAmount}
                    type="number"
                    onInput={(e, value) =>
                      setFineAmount(parseInt(value, 10) || 0)}
                    placeholder="Amount"
                  />
                  <Input
                    value={fineReason}
                    onInput={(e, value) => setFineReason(value)}
                    placeholder="Reason"
                  />
                  <Button onClick={() => act('issue_fine', { target_ckey: targetCkey, amount: fineAmount, reason: fineReason })}>
                    Issue Fine
                  </Button>
                </Flex>
              </Section>
            </>
          )}

          <Section title="Outstanding Fines">
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Amount</Table.Cell>
                <Table.Cell>Reason</Table.Cell>
              </Table.Row>
              {outstanding_fines.map(fine => (
                <Table.Row key={fine.target_ckey + fine.amount}>
                  <Table.Cell>{fine.target_name}</Table.Cell>
                  <Table.Cell>{fine.amount} caps</Table.Cell>
                  <Table.Cell>{fine.reason}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
