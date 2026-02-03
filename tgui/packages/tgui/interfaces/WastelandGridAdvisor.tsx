import { useBackend } from '../backend';
import { Box, Button, LabeledList, NumberInput, Section, Table } from '../components';
import { Window } from '../layouts';

type RecommendationRow = {
  id: string;
  sev: number;
  title: string;
  detail: string;
  key: string;
  val: number;
};

type Plan = {
  rods: number;
  coolant: number;
  feedwater: number;
  relief: number;
  bypass: number;
  turbine: number;
  target: number;
  boron: number;
  scram: number;
  interlocks: number;
};

type Data = {
  advisor_name: string;
  online: boolean;
  state: string;
  bg_rads: number;
  heat: number;
  pressure: number;
  flow: number;
  output: number;
  target_output: number;
  subcool: number;
  npsh: number;
  xenon: number;
  iodine: number;
  samarium: number;
  boron: number;
  scram: boolean;
  interlocks: boolean;
  catastrophe_risk: number;
  catastrophe_triggered: boolean;
  auto_enabled: boolean;
  auto_active: boolean;
  auto_threshold: number;
  active_players: number;
  plan: Plan;
  recs: RecommendationRow[];
};

export const meta = {
  title: 'Grid Advisor',
  width: 760,
  height: 680,
};

const sevText = (sev: number) => {
  if (sev >= 3) {
    return 'CRITICAL';
  }
  if (sev === 2) {
    return 'WARN';
  }
  if (sev === 1) {
    return 'INFO';
  }
  return 'OK';
};

export const WastelandGridAdvisor = (props, context) => {
  const { act, data } = useBackend<Data>(context);

  if (!data) {
    return (
      <Window width={760} height={680}>
        <Window.Content>Loading...</Window.Content>
      </Window>
    );
  }

  const plan = data.plan || ({} as Plan);
  const recs = data.recs || [];

  const planRows = [
    { label: 'Rods', key: 'rods', value: plan.rods },
    { label: 'Coolant valve', key: 'coolant', value: plan.coolant },
    { label: 'Feedwater valve', key: 'feedwater', value: plan.feedwater },
    { label: 'Relief valve', key: 'relief', value: plan.relief },
    { label: 'Bypass', key: 'bypass', value: plan.bypass },
    { label: 'Turbine governor', key: 'turbine', value: plan.turbine },
    { label: 'Target output', key: 'target', value: plan.target },
    { label: 'Boron ppm', key: 'boron', value: plan.boron },
  ];

  return (
    <Window width={760} height={680}>
      <Window.Content scrollable>
        <Section title={data.advisor_name || 'Reactor Advisor'}>
          <Box>
            <Button icon="check" onClick={() => act('apply_all')}>
              Apply all recommendations
            </Button>
            <Button icon="print" onClick={() => act('print_report')}>
              Print report
            </Button>
            <Button
              icon="robot"
              color={data.auto_enabled ? 'green' : 'default'}
              onClick={() => act('toggle_auto')}>
              {data.auto_enabled ? 'Auto ops ON' : 'Auto ops OFF'}
            </Button>
          </Box>
        </Section>

        <Section title="Plant Snapshot">
          <LabeledList>
            <LabeledList.Item label="Grid">{data.online ? 'ONLINE' : 'OFFLINE'} ({data.state})</LabeledList.Item>
            <LabeledList.Item label="Output / Target">{data.output}% / {data.target_output}%</LabeledList.Item>
            <LabeledList.Item label="Heat / Primary P / Flow">{data.heat} / {data.pressure} / {data.flow}</LabeledList.Item>
            <LabeledList.Item label="Subcool / NPSH">{data.subcool} / {data.npsh}</LabeledList.Item>
            <LabeledList.Item label="Xenon / Iodine / Samarium">{data.xenon} / {data.iodine} / {data.samarium}</LabeledList.Item>
            <LabeledList.Item label="Boron / Background rads">{data.boron} ppm / {data.bg_rads}</LabeledList.Item>
            <LabeledList.Item label="SCRAM / Interlocks">{data.scram ? 'ON' : 'OFF'} / {data.interlocks ? 'ON' : 'OFF'}</LabeledList.Item>
            <LabeledList.Item label="Catastrophe risk">{data.catastrophe_risk}% {data.catastrophe_triggered ? '(triggered)' : ''}</LabeledList.Item>
            <LabeledList.Item label="Auto ops">
              {data.auto_enabled ? 'Enabled' : 'Disabled'} | {data.auto_active ? 'Active' : 'Standby'} ({data.active_players}/{data.auto_threshold})
            </LabeledList.Item>
            <LabeledList.Item label="Auto threshold">
              <NumberInput
                value={data.auto_threshold}
                minValue={1}
                maxValue={120}
                onChange={(_, v) => act('set_auto_threshold', { val: v })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <Section title="Recommended Setpoints">
          <Table>
            <Table.Row header>
              <Table.Cell>Setting</Table.Cell>
              <Table.Cell>Recommended</Table.Cell>
              <Table.Cell>Apply</Table.Cell>
            </Table.Row>
            {planRows.map((row) => (
              <Table.Row key={row.key}>
                <Table.Cell>{row.label}</Table.Cell>
                <Table.Cell>{row.value ?? '-'}</Table.Cell>
                <Table.Cell>
                  <Button onClick={() => act('apply_one', { key: row.key, val: row.value })}>
                    Apply
                  </Button>
                </Table.Cell>
              </Table.Row>
            ))}
            <Table.Row>
              <Table.Cell>Safety interlocks</Table.Cell>
              <Table.Cell>{plan.interlocks ? 'ENABLE' : 'No change'}</Table.Cell>
              <Table.Cell>
                <Button onClick={() => act('apply_one', { key: 'interlocks', val: plan.interlocks })}>
                  Apply
                </Button>
              </Table.Cell>
            </Table.Row>
            <Table.Row>
              <Table.Cell>SCRAM command</Table.Cell>
              <Table.Cell>{plan.scram ? 'ENGAGE' : 'No SCRAM needed'}</Table.Cell>
              <Table.Cell>
                <Button disabled={!plan.scram} color="red" onClick={() => act('apply_one', { key: 'scram', val: 1 })}>
                  Engage SCRAM
                </Button>
              </Table.Cell>
            </Table.Row>
          </Table>
        </Section>

        <Section title="Advisor Guidance">
          {!recs.length ? (
            <Box>No guidance generated.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Severity</Table.Cell>
                <Table.Cell>Issue</Table.Cell>
                <Table.Cell>Recommendation</Table.Cell>
                <Table.Cell>Quick Apply</Table.Cell>
              </Table.Row>
              {recs.map((rec) => (
                <Table.Row key={rec.id}>
                  <Table.Cell>{sevText(rec.sev)}</Table.Cell>
                  <Table.Cell>{rec.title}</Table.Cell>
                  <Table.Cell>{rec.detail}</Table.Cell>
                  <Table.Cell>
                    {!!rec.key && rec.sev > 0 ? (
                      <Button onClick={() => act('apply_one', { key: rec.key, val: rec.val })}>
                        Apply
                      </Button>
                    ) : (
                      '-'
                    )}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

export default WastelandGridAdvisor;
