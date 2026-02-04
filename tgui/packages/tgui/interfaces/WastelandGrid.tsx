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

type AuctionBidRow = {
  district: string;
  faction: string;
  request_mw: number;
  bid_caps: number;
};

type AuctionAllocRow = {
  district: string;
  mw: number;
};

type DispatchRow = {
  id: string;
  type: string;
  district: string;
  sev: number;
  desc: string;
  expires_s: number;
  resolved: boolean;
};

type TheftRow = {
  district: string;
  intensity: number;
};

type Data = {
  online: boolean;
  state: string;
  bg_rads: number;
  scram: boolean;
  interlocks: boolean;
  catastrophe_risk: number;
  catastrophe_triggered: boolean;
  auto_enabled: boolean;
  auto_active: boolean;
  auto_threshold: number;
  active_players: number;
  fault_suppression_active: boolean;
  fault_suppression_threshold: number;
  can_debug: boolean;
  debug_enabled: boolean;

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
  output_mw: number;
  output_mw_max: number;
  turbine_stress: number;
  turbine_moisture: number;

  sp_rods: number;
  sp_coolant_valve: number;
  sp_feedwater: number;
  sp_relief: number;
  sp_bypass: number;
  sp_target: number;
  sp_turbine: number;
  sp_boron: number;

  xenon: number;
  iodine: number;
  samarium: number;
  burnup: number;
  react_reserve: number;
  decay_heat: number;
  boron: number;
  doppler_coeff: number;
  mtc_coeff: number;
  subcool_margin: number;
  npsh_margin: number;
  pzr_level: number;
  condenser_vac: number;
  hotwell: number;

  contam: number;
  clog: number;
  lube: number;

  wear_pump: number;
  wear_valves: number;
  wear_turbine: number;
  wear_breakers: number;
  wear_sensors: number;

  faults: FaultRow[];
  maint: MaintRow[];

  purge_stage: number;
  purge_lock: boolean;

  plant_points: number;
  upg_stability: number;
  upg_peak_output: number;
  upg_automation: number;
  upg_safety: number;

  add_anticorrosion: number;
  add_antifoam: number;
  add_flowboost: number;
  stock_anticorrosion: number;
  stock_antifoam: number;
  stock_flowboost: number;

  turbine_bearing_cond: number;
  turbine_blade_cond: number;
  turbine_alignment_cond: number;
  overhaul_active: boolean;
  overhaul_step: string;
  overhaul_bonus_s: number;

  auction_round: number;
  auction_open: boolean;
  auction_remaining_s: number;
  auction_committed_mw: number;
  auction_base_supply_mw: number;
  auction_bids: AuctionBidRow[];
  auction_allocs: AuctionAllocRow[];
  auction_districts: string[];

  dispatch_calls: DispatchRow[];

  spent_fuel_units: number;
  casks_staged: number;
  casks_stored: number;
  casks_processed: number;
  waste_hazard: number;

  theft_load_mw: number;
  forensics_ready: boolean;
  theft_rows: TheftRow[];
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
  const [auctionDistrict, setAuctionDistrict] = useLocalState(context, 'wg_auction_district', 'BOS');
  const [auctionMw, setAuctionMw] = useLocalState(context, 'wg_auction_mw', 30);
  const [auctionCaps, setAuctionCaps] = useLocalState(context, 'wg_auction_caps', 500);
  const [additiveAmt, setAdditiveAmt] = useLocalState(context, 'wg_add_amt', 5);

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
            <Button
              icon="robot"
              color={data.auto_enabled ? 'green' : 'default'}
              onClick={() => act('toggle_auto')}>
              {data.auto_enabled ? 'AUTO OPS ON' : 'AUTO OPS OFF'}
            </Button>
            {!!data.can_debug && (
              <Button
                icon="bug"
                color={data.debug_enabled ? 'yellow' : 'default'}
                onClick={() => act('toggle_debug_controls')}>
                {data.debug_enabled ? 'DEBUG ON' : 'DEBUG OFF'}
              </Button>
            )}
            {!!data.can_debug && !!data.debug_enabled && (
              <Button
                icon="bomb"
                color="red"
                onClick={() => act('debug_blow_reactor')}>
                DEBUG MELTDOWN
              </Button>
            )}
            <Button onClick={() => act('shutdown')}>Shutdown</Button>
            <Button onClick={() => act('prime_restart')}>Prime</Button>
            <Button onClick={() => act('engage_restart')}>Engage</Button>
          </Box>

          <Tabs>
            {['Status', 'Controls', 'Plant', 'Auctions', 'Dispatch', 'Logistics', 'Security', 'Faults', 'Maintenance', 'Procedures'].map((t) => (
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
              <LabeledList.Item label="Export power">
                {data.output_mw} MW / {data.output_mw_max} MW max
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
              <LabeledList.Item label="Turbine stress/moisture">
                {data.turbine_stress}% / {data.turbine_moisture}%
              </LabeledList.Item>
              <LabeledList.Item label="Fuel / Coolant">
                {data.fuel} / {data.coolant}
              </LabeledList.Item>
              <LabeledList.Item label="Xenon / Iodine / Samarium">
                {data.xenon} / {data.iodine} / {data.samarium}
              </LabeledList.Item>
              <LabeledList.Item label="Burnup / Reserve / Decay">
                {data.burnup}% / {data.react_reserve} / {data.decay_heat}
              </LabeledList.Item>
              <LabeledList.Item label="Boron / Subcool">
                {data.boron} ppm / {data.subcool_margin}
              </LabeledList.Item>
              <LabeledList.Item label="NPSH margin">{data.npsh_margin}</LabeledList.Item>
              <LabeledList.Item label="Doppler / MTC">
                {data.doppler_coeff} / {data.mtc_coeff}
              </LabeledList.Item>
              <LabeledList.Item label="PZR / Vacuum / Hotwell">
                {data.pzr_level}% / {data.condenser_vac}% / {data.hotwell}%
              </LabeledList.Item>
              <LabeledList.Item label="Background rads">{data.bg_rads}</LabeledList.Item>
              <LabeledList.Item label="Safety interlocks">
                {data.interlocks ? 'Enabled' : 'Disabled'}
              </LabeledList.Item>
              <LabeledList.Item label="Catastrophe risk">
                {data.catastrophe_risk}% {data.catastrophe_triggered ? '(Core destroyed)' : ''}
              </LabeledList.Item>
              <LabeledList.Item label="Auto operations">
                {data.auto_enabled ? 'Enabled' : 'Disabled'} | {data.auto_active ? 'Active' : 'Standby'} (players {data.active_players}/{data.auto_threshold})
              </LabeledList.Item>
              <LabeledList.Item label="Low-pop protections">
                {data.fault_suppression_active ? 'ACTIVE' : 'Inactive'} (fault/maintenance suppression below {data.fault_suppression_threshold} players)
              </LabeledList.Item>
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
                  <Box color="label">
                    Approx export at current conditions: {data.output_mw} MW
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Turbine governor">
                  <NumberInput
                    value={data.sp_turbine}
                    minValue={0}
                    maxValue={100}
                    onChange={(_, v) => setSP('turbine', v)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Boron ppm">
                  <NumberInput
                    value={data.sp_boron}
                    minValue={0}
                    maxValue={2000}
                    onChange={(_, v) => setSP('boron', v)}
                  />
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
              <Box mt={1}>
                <Button
                  icon="robot"
                  color={data.auto_enabled ? 'green' : 'default'}
                  onClick={() => act('toggle_auto')}>
                  {data.auto_enabled ? 'Disable auto operations' : 'Enable auto operations'}
                </Button>
              </Box>
            </Section>
          )}

          {tab === 'Plant' && (
            <Section title="Plant Programs">
              <LabeledList>
                <LabeledList.Item label="Upgrade points">{data.plant_points}</LabeledList.Item>
                <LabeledList.Item label="Upgrade tiers">
                  Stability {data.upg_stability} | Peak {data.upg_peak_output} | Auto {data.upg_automation} | Safety {data.upg_safety}
                </LabeledList.Item>
                <LabeledList.Item label="Turbine condition">
                  Bearing {data.turbine_bearing_cond}% | Blade {data.turbine_blade_cond}% | Align {data.turbine_alignment_cond}%
                </LabeledList.Item>
                <LabeledList.Item label="Overhaul">
                  {data.overhaul_active ? `Active (${data.overhaul_step})` : 'Idle'} {data.overhaul_bonus_s > 0 ? `| Bonus ${data.overhaul_bonus_s}s` : ''}
                </LabeledList.Item>
                <LabeledList.Item label="Additives active">
                  Anti-corrosion {data.add_anticorrosion}% | Anti-foam {data.add_antifoam}% | Flow boost {data.add_flowboost}%
                </LabeledList.Item>
                <LabeledList.Item label="Additive stock">
                  A/C {data.stock_anticorrosion} | A/F {data.stock_antifoam} | F/B {data.stock_flowboost}
                </LabeledList.Item>
                <LabeledList.Item label="Dose amount">
                  <NumberInput value={additiveAmt} minValue={1} maxValue={25} onChange={(_, v) => setAdditiveAmt(v)} />
                </LabeledList.Item>
              </LabeledList>
              <Box mt={1}>
                <Button onClick={() => act('buy_upgrade', { key: 'stability' })}>Buy Stability</Button>
                <Button onClick={() => act('buy_upgrade', { key: 'peak_output' })}>Buy Peak Output</Button>
                <Button onClick={() => act('buy_upgrade', { key: 'automation' })}>Buy Automation</Button>
                <Button onClick={() => act('buy_upgrade', { key: 'safety' })}>Buy Safety</Button>
              </Box>
              <Box mt={1}>
                <Button onClick={() => act('inject_additive', { key: 'anticorrosion', amt: additiveAmt })}>Inject Anti-Corrosion</Button>
                <Button onClick={() => act('inject_additive', { key: 'antifoam', amt: additiveAmt })}>Inject Anti-Foam</Button>
                <Button onClick={() => act('inject_additive', { key: 'flowboost', amt: additiveAmt })}>Inject Flow Boost</Button>
              </Box>
              <Box mt={1}>
                <Button disabled={data.overhaul_active} onClick={() => act('start_overhaul')}>Start Overhaul</Button>
                <Button disabled={!data.overhaul_active} onClick={() => act('progress_overhaul', { step: 'bearing' })}>Complete Bearing Step</Button>
                <Button disabled={!data.overhaul_active} onClick={() => act('progress_overhaul', { step: 'blade' })}>Complete Blade Step</Button>
                <Button disabled={!data.overhaul_active} onClick={() => act('progress_overhaul', { step: 'alignment' })}>Complete Alignment Step</Button>
              </Box>
            </Section>
          )}

          {tab === 'Auctions' && (
            <Section title="Grid Power Auctions">
              <LabeledList>
                <LabeledList.Item label="Round">
                  {data.auction_round} ({data.auction_open ? `OPEN ${data.auction_remaining_s}s` : 'CLOSED'})
                </LabeledList.Item>
                <LabeledList.Item label="Supply / committed">
                  {data.auction_base_supply_mw}MW / {data.auction_committed_mw}MW
                </LabeledList.Item>
                <LabeledList.Item label="District">
                  <Box>
                    {data.auction_districts?.map((d) => (
                      <Button key={d} color={auctionDistrict === d ? 'green' : 'default'} onClick={() => setAuctionDistrict(d)}>
                        {d}
                      </Button>
                    ))}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Request MW">
                  <NumberInput value={auctionMw} minValue={5} maxValue={120} onChange={(_, v) => setAuctionMw(v)} />
                </LabeledList.Item>
                <LabeledList.Item label="Bid caps">
                  <NumberInput value={auctionCaps} minValue={50} maxValue={5000} onChange={(_, v) => setAuctionCaps(v)} />
                </LabeledList.Item>
              </LabeledList>
              <Box mt={1}>
                <Button disabled={!data.auction_open} onClick={() => act('bid_power', { district: auctionDistrict, mw: auctionMw, caps: auctionCaps })}>
                  Submit Bid
                </Button>
              </Box>
              <Section title="Bids">
                {(!data.auction_bids || data.auction_bids.length === 0) ? <Box>No bids yet.</Box> : (
                  <Table>
                    <Table.Row header><Table.Cell>District</Table.Cell><Table.Cell>Faction</Table.Cell><Table.Cell>MW</Table.Cell><Table.Cell>Caps</Table.Cell></Table.Row>
                    {data.auction_bids.map((b) => <Table.Row key={`${b.district}-${b.faction}`}><Table.Cell>{b.district}</Table.Cell><Table.Cell>{b.faction}</Table.Cell><Table.Cell>{b.request_mw}</Table.Cell><Table.Cell>{b.bid_caps}</Table.Cell></Table.Row>)}
                  </Table>
                )}
              </Section>
              <Section title="Current Allocations">
                {(!data.auction_allocs || data.auction_allocs.length === 0) ? <Box>No allocations yet.</Box> : (
                  <Table>
                    <Table.Row header><Table.Cell>District</Table.Cell><Table.Cell>MW</Table.Cell></Table.Row>
                    {data.auction_allocs.map((a) => <Table.Row key={a.district}><Table.Cell>{a.district}</Table.Cell><Table.Cell>{a.mw}</Table.Cell></Table.Row>)}
                  </Table>
                )}
              </Section>
            </Section>
          )}

          {tab === 'Dispatch' && (
            <Section title="Emergency Dispatch Console">
              {(!data.dispatch_calls || data.dispatch_calls.length === 0) ? <Box>No active calls.</Box> : (
                <Table>
                  <Table.Row header><Table.Cell>ID</Table.Cell><Table.Cell>Type</Table.Cell><Table.Cell>District</Table.Cell><Table.Cell>S</Table.Cell><Table.Cell>TTL</Table.Cell><Table.Cell>Action</Table.Cell></Table.Row>
                  {data.dispatch_calls.map((c) => (
                    <Table.Row key={c.id}>
                      <Table.Cell>{c.id}</Table.Cell>
                      <Table.Cell>{c.type}</Table.Cell>
                      <Table.Cell>{c.district}</Table.Cell>
                      <Table.Cell>{c.sev}</Table.Cell>
                      <Table.Cell>{c.expires_s}s</Table.Cell>
                      <Table.Cell>
                        <Button disabled={c.resolved} onClick={() => act('resolve_dispatch', { id: c.id })}>Resolve</Button>
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          )}

          {tab === 'Logistics' && (
            <Section title="Spent Fuel & Waste Chain">
              <LabeledList>
                <LabeledList.Item label="Spent fuel units">{data.spent_fuel_units}</LabeledList.Item>
                <LabeledList.Item label="Casks (staged/stored/processed)">
                  {data.casks_staged} / {data.casks_stored} / {data.casks_processed}
                </LabeledList.Item>
                <LabeledList.Item label="Waste hazard">{data.waste_hazard}%</LabeledList.Item>
              </LabeledList>
              <Box mt={1}>
                <Button onClick={() => act('stage_cask')}>Package Cask</Button>
                <Button onClick={() => act('store_cask')}>Move To Storage</Button>
                <Button onClick={() => act('process_cask')}>Process Cask</Button>
              </Box>
            </Section>
          )}

          {tab === 'Security' && (
            <Section title="Power Theft & Forensics">
              <LabeledList>
                <LabeledList.Item label="Detected theft load">{data.theft_load_mw} MW</LabeledList.Item>
              </LabeledList>
              <Box mt={1}>
                <Button disabled={!data.forensics_ready} onClick={() => act('run_forensics')}>
                  {data.forensics_ready ? 'Run Forensics Scan' : 'Scanner Cooling Down'}
                </Button>
              </Box>
              <Table>
                <Table.Row header><Table.Cell>District</Table.Cell><Table.Cell>Intensity</Table.Cell><Table.Cell>Action</Table.Cell></Table.Row>
                {data.theft_rows?.map((r) => (
                  <Table.Row key={r.district}>
                    <Table.Cell>{r.district}</Table.Cell>
                    <Table.Cell>{r.intensity}</Table.Cell>
                    <Table.Cell><Button disabled={r.intensity <= 0} onClick={() => act('shutdown_tap', { district: r.district })}>Shutdown Tap</Button></Table.Cell>
                  </Table.Row>
                ))}
              </Table>
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
                <Button
                  color={data.interlocks ? 'red' : 'green'}
                  disabled={data.catastrophe_triggered}
                  onClick={() => act('toggle_interlocks')}>
                  {data.interlocks ? 'Disable safety interlocks' : 'Enable safety interlocks'}
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
