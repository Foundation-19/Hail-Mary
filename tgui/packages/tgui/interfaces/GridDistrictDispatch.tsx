import { useBackend, useLocalState } from '../backend';
import { Box, Button, LabeledList, NumberInput, Section, Table, Tabs } from '../components';
import { Window } from '../layouts';

type DistrictRow = {
  faction: string;
  district: string;
  routed_on: boolean;
  forced_off: boolean;
  remaining_s: number;
};

type Data = {
  online: boolean;
  state: string;
  default_outage_s: number;
  rows: DistrictRow[];
};

export const meta = {
  title: 'District Dispatch',
  width: 760,
  height: 560,
};

const getStatusText = (row: DistrictRow) => {
  if (row.forced_off) {
    return 'OFF (Forced)';
  }
  if (row.remaining_s > 0) {
    return `OFF (${row.remaining_s}s timed)`;
  }
  return row.routed_on ? 'ON' : 'OFF';
};

export const GridDistrictDispatch = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const [tab, setTab] = useLocalState(context, 'gdd_tab', 'Overview');
  const [outageSeconds, setOutageSeconds] = useLocalState(context, 'gdd_outage', 90);

  if (!data) {
    return (
      <Window width={760} height={560}>
        <Window.Content>Loading...</Window.Content>
      </Window>
    );
  }

  const rows = data.rows || [];
  const tabNames = ['Overview', ...rows.map((r) => r.faction)];
  const selectedTab = tabNames.includes(tab) ? tab : 'Overview';
  const selectedRow = rows.find((r) => r.faction === selectedTab);

  return (
    <Window width={760} height={560}>
      <Window.Content scrollable>
        <Section title="Reactor District Dispatch">
          <LabeledList>
            <LabeledList.Item label="Grid">{data.online ? 'ONLINE' : 'OFFLINE'}</LabeledList.Item>
            <LabeledList.Item label="State">{data.state || 'UNKNOWN'}</LabeledList.Item>
            <LabeledList.Item label="Default outage">{data.default_outage_s || 90}s</LabeledList.Item>
          </LabeledList>
          <Box mt={1} color="average">
            This console routes district power per faction using reactor controls.
          </Box>
        </Section>

        <Tabs>
          {tabNames.map((name) => (
            <Tabs.Tab key={name} selected={selectedTab === name} onClick={() => setTab(name)}>
              {name}
            </Tabs.Tab>
          ))}
        </Tabs>

        {selectedTab === 'Overview' && (
          <Section title="Faction Districts">
            {!rows.length ? (
              <Box color="average">No faction districts configured on this console.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>Faction</Table.Cell>
                  <Table.Cell>District</Table.Cell>
                  <Table.Cell>Status</Table.Cell>
                  <Table.Cell>Quick Actions</Table.Cell>
                </Table.Row>
                {rows.map((row) => (
                  <Table.Row key={row.faction}>
                    <Table.Cell>{row.faction}</Table.Cell>
                    <Table.Cell>{row.district || '-'}</Table.Cell>
                    <Table.Cell>{getStatusText(row)}</Table.Cell>
                    <Table.Cell>
                      <Button onClick={() => act('route_on', { faction: row.faction })}>ON</Button>
                      <Button onClick={() => act('route_off', { faction: row.faction })}>OFF</Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}

        {!!selectedRow && (
          <Section title={`${selectedRow.faction} Controls`}>
            <LabeledList>
              <LabeledList.Item label="District">{selectedRow.district || '-'}</LabeledList.Item>
              <LabeledList.Item label="Status">{getStatusText(selectedRow)}</LabeledList.Item>
            </LabeledList>

            <Box mt={1}>
              <Button onClick={() => act('route_on', { faction: selectedRow.faction })}>
                Route ON
              </Button>
              <Button onClick={() => act('route_off', { faction: selectedRow.faction })}>
                Route OFF
              </Button>
            </Box>

            <Box mt={1}>
              <Section title="Timed Outage">
                <LabeledList>
                  <LabeledList.Item label="Duration (15-600s)">
                    <NumberInput
                      value={outageSeconds}
                      minValue={15}
                      maxValue={600}
                      onChange={(_, value) => setOutageSeconds(value)}
                    />
                  </LabeledList.Item>
                </LabeledList>
                <Button
                  onClick={() =>
                    act('timed_outage', { faction: selectedRow.faction, seconds: outageSeconds })
                  }>
                  Schedule Outage
                </Button>
              </Section>
            </Box>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

export default GridDistrictDispatch;
