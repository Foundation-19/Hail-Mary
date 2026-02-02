import { useBackend, useLocalState } from '../backend';

import { Box, Button, LabeledList, NumberInput, Section, Tabs, Table } from '../components';
import { Window } from '../layouts';

type FaultRow = {
  id: string;
  name: string;
  sev: number;
  loc: string;
  cause: string;
  needs_tool: string;
  needs_parts: string;
};

type MaintRow = {
  id: string;
  name: string;
  sev: number;
  desc: string;
  tag?: string;
};

type AlarmRow = {
  id: string;
  sev: number;
};

type Data = {
  online: boolean;
  state: string;
  bg_rads: number;
  scram: boolean;

  fuel: number;
  coolant: number;
  restart_stage: number;

  heat_actual: number;
  heat_disp: number;
  reactivity: number;
  flow_actual: number;
  flow_disp: number;
  p_primary_actual: number;
  p_primary_disp: number;
  p_secondary: number;
  steam_q: number;
  rpm: number;
  output: number;

  sp_rods: number;
  sp_coolant_valve: number;
  sp_feedwater: number;
  sp_relief: number;
  sp_bypass: number;
  sp_target: number;

  contam: number;
  clog: number;
  lube: number;

  wear_pump: number;
  wear_valves: number;
  wear_turbine: number;
  wear_breakers: number;
  wear_sensors: number;

  alarms: AlarmRow[];
  faults: FaultRow[];
  maint: MaintRow[];

  purge_stage: number;
  purge_lock: boolean;
};

export const meta = {
  title: 'Wasteland Grid',
  width: 620,
  height: 700,
};

export const WastelandGrid = (props, context) => {
  const { act, data } = useBackend<Data>(context);

  // Prevent first-render crash if ui_data hasn't arrived yet
  if (!data) {
    return (
      <Window width={620} height={700}>
        <Window.Content>Loading...</Window.Content>
      </Window>
    );
  }

  // useLocalState expects the UI context (props)
  const [tab, setTab] = useLocalState(context, 'wg_tab', 'Status');

  const setSP = (key: string, val: number) => act('set_sp', { key, val });

  return (
    <Window width={620} height={700}>
      <Window.Content scrollable>
        <Section title={`Grid: ${data.online ? 'ONLINE' : 'OFFLINE'} (${data.state})`}>
          <Box>
            <Button
              icon="radiation"
              color={data.scram ? 'red' : 'default'}
              onClick={() => act('toggle_scram')}>
              {data.scram ? 'SCRAM ACTIVE' : 'SCRAM'}
            </Button>
            <Button onClick={() => act('shutdown')}>Shutdown</Button>
            <Button onClick={() => act('prime_restart')}>Prime</Button>
            <Button onClick={() => act('engage_restart')}>Engage</Button>
          </Box>

          <Tabs>
            {['Status', 'Controls', 'Alarms', 'Faults', 'Maintenance', 'Procedures'].map((t) => (
              <Tabs.Tab key={t} selected={tab === t} onClick={() => setTab(t)}>
                {t}
              </Tabs.Tab>
            ))}
          </Tabs>

          {tab === 'Status' && (
            <LabeledList>
              <LabeledList.Item label="Output">
                {data.output}% (Target {data.sp_target}%)
              </LabeledList.Item>
              <LabeledList.Item label="Heat">
                {data.heat_disp} (actual {data.heat_actual})
              </LabeledList.Item>
              <LabeledList.Item label="Primary P">
                {data.p_primary_disp} (actual {data.p_primary_actual})
              </LabeledList.Item>
              <LabeledList.Item label="Flow">
                {data.flow_disp} (actual {data.flow_actual})
              </LabeledList.Item>
              <LabeledList.Item label="RPM">{data.rpm}</LabeledList.Item>
              <LabeledList.Item label="Fuel / Coolant">
                {data.fuel} / {data.coolant}
              </LabeledList.Item>
              <LabeledList.Item label="Background rads">{data.bg_rads}</LabeledList.Item>
              <LabeledList.Item label="Chemistry">
                Contam {data.contam}% | Clog {data.clog}% | Lube {data.lube}%
              </LabeledList.Item>
              <LabeledList.Item label="Wear">
                P/V/T/B/S: {data.wear_pump}/{data.wear_valves}/{data.wear_turbine}/{data.wear_breakers}/{data.wear_sensors}
              </LabeledList.Item>
            </LabeledList>
          )}

          {tab === 'Controls' && (
            <Section title="Setpoints">
              <LabeledList>
                <LabeledList.Item label="Rods">
                  <NumberInput
                    value={data.sp_rods}
                    minValue={0}
                    maxValue={100}
                    onChange={(_, v) => setSP('rods', v)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Coolant valve">
                  <NumberInput
                    value={data.sp_coolant_valve}
                    minValue={0}
                    maxValue={100}
                    onChange={(_, v) => setSP('coolant', v)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Feedwater">
                  <NumberInput
                    value={data.sp_feedwater}
                    minValue={0}
                    maxValue={100}
                    onChange={(_, v) => setSP('feedwater', v)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Relief">
                  <NumberInput
                    value={data.sp_relief}
                    minValue={0}
                    maxValue={100}
                    onChange={(_, v) => setSP('relief', v)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Bypass">
                  <NumberInput
                    value={data.sp_bypass}
                    minValue={0}
                    maxValue={100}
                    onChange={(_, v) => setSP('bypass', v)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Target output">
                  <NumberInput
                    value={data.sp_target}
                    minValue={0}
                    maxValue={100}
                    onChange={(_, v) => setSP('target', v)}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Section>
          )}

          {tab === 'Alarms' && (
            <Section title="Active Alarms">
              {(!data.alarms || data.alarms.length === 0) ? (
                <Box>No alarms.</Box>
              ) : (
                <Table>
                  <Table.Row header>
                    <Table.Cell>Alarm</Table.Cell>
                    <Table.Cell>Severity</Table.Cell>
                  </Table.Row>
                  {data.alarms.map((a) => (
                    <Table.Row key={a.id}>
                      <Table.Cell>{a.id}</Table.Cell>
                      <Table.Cell>{a.sev}</Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          )}

          {tab === 'Faults' && (
            <Section title="Faults">
              {(!data.faults || data.faults.length === 0) ? (
                <Box>No faults.</Box>
              ) : (
                <Table>
                  <Table.Row header>
                    <Table.Cell>Name</Table.Cell>
                    <Table.Cell>S</Table.Cell>
                    <Table.Cell>Location</Table.Cell>
                    <Table.Cell>Needs</Table.Cell>
                  </Table.Row>
                  {data.faults.map((f) => (
                    <Table.Row key={f.id}>
                      <Table.Cell>{f.name}</Table.Cell>
                      <Table.Cell>{f.sev}</Table.Cell>
                      <Table.Cell>{f.loc}</Table.Cell>
                      <Table.Cell>{f.needs_tool}; {f.needs_parts}</Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          )}

          {tab === 'Maintenance' && (
            <Section title="Maintenance Queue">
              {(!data.maint || data.maint.length === 0) ? (
                <Box>None.</Box>
              ) : (
                <Table>
                  <Table.Row header>
                    <Table.Cell>Task</Table.Cell>
                    <Table.Cell>S</Table.Cell>
                    <Table.Cell>Target</Table.Cell>
                  </Table.Row>
                  {data.maint.map((m) => (
                    <Table.Row key={m.id}>
                      <Table.Cell>{m.name}</Table.Cell>
                      <Table.Cell>{m.sev}</Table.Cell>
                      <Table.Cell>{m.tag || '-'}</Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          )}

          {tab === 'Procedures' && (
            <Section title="Procedures">
              <Box>
                Purge stage: {data.purge_stage} {data.purge_lock ? '(active)' : ''}
              </Box>
              <Box mt={1}>
                <Button disabled={data.purge_lock} onClick={() => act('start_purge')}>
                  Start purge
                </Button>
                <Button disabled={!data.purge_lock} onClick={() => act('abort_purge')}>
                  Abort purge
                </Button>
              </Box>
            </Section>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

export default WastelandGrid;
