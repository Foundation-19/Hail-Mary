import { useBackend, useLocalState } from '../backend';
import { Box, Button, LabeledList, Section, Table, Tabs } from '../components';
import { Window } from '../layouts';

type DistrictRow = {
  district: string;
  owner: string;
  income: number;
  effective_income: number;
  grid_on: boolean;
  power_ok: boolean;
  water_ok: boolean;
  logistics_ok: boolean;
  water_level: number;
  logistics_health: number;
  stability: number;
  jammed: boolean;
  buildable_kind: string;
  buildable_name: string;
  industry_lvl: number;
  logistics_lvl: number;
  security_lvl: number;
  is_owned_by_you: boolean;
};

type ContractRow = {
  id: string;
  title: string;
  type: string;
  district: string;
  desc: string;
  target: number;
  progress: number;
  complete: boolean;
  reward_caps: number;
  reward_rep: number;
  reward_research: number;
  expires_s: number;
};

type UpgradeRow = {
  district: string;
  owner: string;
  is_owned_by_you: boolean;
  industry_lvl: number;
  logistics_lvl: number;
  security_lvl: number;
  industry_cost: number;
  logistics_cost: number;
  security_cost: number;
  industry_next: string;
  logistics_next: string;
  security_next: string;
};

type EventRow = {
  id: string;
  title: string;
  type: string;
  district: string;
  desc: string;
  remaining_s: number;
};

type CaravanRow = {
  id: string;
  from_district: string;
  to_district: string;
  eta_s: number;
  reward_caps: number;
  is_enemy: boolean;
  faction: string;
  compromised: boolean;
  manifest: string;
};

type WaterRow = {
  id: string;
  district: string;
  owner: string;
  mode: string;
  output: number;
  operational: boolean;
  is_owner: boolean;
};

type HazardRow = {
  id: string;
  district: string;
  type: string;
  title: string;
  desc: string;
  remaining_s: number;
  mult: number;
};

type BuildableRow = {
  district: string;
  owner: string;
  buildable_name: string;
  buildable_kind: string;
  is_owned_by_you: boolean;
  can_deploy: boolean;
  blocked_reason: string;
};

type RepRow = {
  ckey: string;
  rep: number;
};

type ResearchRow = {
  id: string;
  name: string;
  track: string;
  tier: number;
  cost: number;
  desc: string;
  effect: string;
  unlocked: boolean;
  available: boolean;
  blocked_reason: string;
};

type Data = {
  faction: string;
  can_control: boolean;
  funds: number;
  supply_cost: number;
  override_cost: number;
  supply_cd: number;
  supply_ready: boolean;
  district_total: number;
  district_owned: number;
  income_owned: number;
  rep: number;
  research_points: number;
  research_tier: number;
  research_next_cost: number;
  research_unlocked_count: number;
  research_projects_total: number;
  rows: DistrictRow[];
  contracts: ContractRow[];
  upgrade_rows: UpgradeRow[];
  research_rows: ResearchRow[];
  events: EventRow[];
  caravans: CaravanRow[];
  top_rep: RepRow[];
  water_rows: WaterRow[];
  hazard_rows: HazardRow[];
  buildable_rows: BuildableRow[];
  intel_points: number;
  intel_reveal_s: number;
  buildable_template_name: string;
  buildable_template_requires: string;
};

export const FactionControl = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const [tab, setTab] = useLocalState(context, 'fc_tab', 'Districts');

  if (!data) {
    return (
      <Window width={900} height={640}>
        <Window.Content>Loading...</Window.Content>
      </Window>
    );
  }

  return (
    <Window width={900} height={640}>
      <Window.Content scrollable>
        <Section title="Faction Control">
          <LabeledList>
            <LabeledList.Item label="Faction">{data.faction || 'None'}</LabeledList.Item>
            <LabeledList.Item label="Treasury">{data.funds || 0}</LabeledList.Item>
            <LabeledList.Item label="Districts">
              {data.district_owned || 0}/{data.district_total || 0}
            </LabeledList.Item>
            <LabeledList.Item label="Owned Income">{data.income_owned || 0}/tick</LabeledList.Item>
            <LabeledList.Item label="Supply Cost">{data.supply_cost || 0}</LabeledList.Item>
            <LabeledList.Item label="Supply Cooldown">
              {Math.max(0, Math.round((data.supply_cd || 0) / 10))}s
            </LabeledList.Item>
            <LabeledList.Item label="Research Tier">{data.research_tier || 0}/4</LabeledList.Item>
            <LabeledList.Item label="Research Pts">{data.research_points || 0}</LabeledList.Item>
            <LabeledList.Item label="Intel Pts">{data.intel_points || 0}</LabeledList.Item>
            <LabeledList.Item label="Route Reveal">{data.intel_reveal_s || 0}s</LabeledList.Item>
            <LabeledList.Item label="Projects">
              {data.research_unlocked_count || 0}/{data.research_projects_total || 0}
            </LabeledList.Item>
            <LabeledList.Item label="Your Reputation">{data.rep || 0}</LabeledList.Item>
          </LabeledList>
          <Box mt={1}>
            <Button
              disabled={!data.can_control || !(data.research_next_cost > 0)}
              onClick={() => act('unlock_research')}>
              Unlock Research ({data.research_next_cost || 0})
            </Button>
          </Box>
          {!data.can_control && (
            <Box color="bad">
              This console is limited to BOS, NCR, Legion, and Town command factions.
            </Box>
          )}
        </Section>

        <Tabs>
          <Tabs.Tab selected={tab === 'Districts'} onClick={() => setTab('Districts')}>
            Districts
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Contracts'} onClick={() => setTab('Contracts')}>
            Contracts
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Upgrades'} onClick={() => setTab('Upgrades')}>
            Upgrades
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Research'} onClick={() => setTab('Research')}>
            Research
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Buildables'} onClick={() => setTab('Buildables')}>
            Buildables
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Logistics'} onClick={() => setTab('Logistics')}>
            Logistics
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Water'} onClick={() => setTab('Water')}>
            Water
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Intel'} onClick={() => setTab('Intel')}>
            Intel
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Events'} onClick={() => setTab('Events')}>
            Events
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'Hazards'} onClick={() => setTab('Hazards')}>
            Hazards
          </Tabs.Tab>
        </Tabs>

        {tab === 'Districts' && (
          <Section title="District Ownership & Actions">
            <Box mb={1} color="average">
              District blackout routing is reactor-controlled now. Use reactor district load controllers for ON/OFF routing.
            </Box>
            {!(data.rows && data.rows.length) ? (
              <Box color="average">No districts discovered yet. Claim a relay node first.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>District</Table.Cell>
                  <Table.Cell>Owner</Table.Cell>
                  <Table.Cell>Income</Table.Cell>
                  <Table.Cell>Utilities</Table.Cell>
                  <Table.Cell>Metrics</Table.Cell>
                  <Table.Cell>Buildable</Table.Cell>
                  <Table.Cell>U: I/L/S</Table.Cell>
                  <Table.Cell>Actions</Table.Cell>
                </Table.Row>
                {(data.rows || []).map((r) => (
                  <Table.Row key={r.district}>
                    <Table.Cell>{r.district}</Table.Cell>
                    <Table.Cell>{r.owner}</Table.Cell>
                    <Table.Cell>
                      {r.income} (eff {r.effective_income})
                    </Table.Cell>
                    <Table.Cell>
                      P:{r.power_ok ? 'ON' : 'OFF'} / W:{r.water_ok ? 'OK' : 'LOW'} / L:{r.logistics_ok ? 'OK' : 'LOW'}
                      {r.jammed ? ' / JAM' : ''}
                    </Table.Cell>
                    <Table.Cell>
                      W {r.water_level} | L {r.logistics_health} | S {r.stability}
                    </Table.Cell>
                    <Table.Cell>{r.buildable_name || '-'}</Table.Cell>
                    <Table.Cell>
                      {r.industry_lvl}/{r.logistics_lvl}/{r.security_lvl}
                    </Table.Cell>
                    <Table.Cell>
                      <Button
                        disabled={!data.can_control || !r.is_owned_by_you || !data.supply_ready}
                        tooltip={data.supply_ready ? '' : 'Supply drop is cooling down.'}
                        onClick={() => act('supply_drop', { district: r.district })}>
                        Supply
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}

        {tab === 'Contracts' && (
          <Section title="Faction Contracts">
            {!(data.contracts && data.contracts.length) ? (
              <Box color="average">No active contracts right now. Check back soon.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>Title</Table.Cell>
                  <Table.Cell>District</Table.Cell>
                  <Table.Cell>Progress</Table.Cell>
                  <Table.Cell>Rewards</Table.Cell>
                  <Table.Cell>Expires</Table.Cell>
                  <Table.Cell>Action</Table.Cell>
                </Table.Row>
                {(data.contracts || []).map((c) => (
                  <Table.Row key={c.id}>
                    <Table.Cell>{c.title}</Table.Cell>
                    <Table.Cell>{c.district || '-'}</Table.Cell>
                    <Table.Cell>
                      {c.progress}/{c.target}
                    </Table.Cell>
                    <Table.Cell>
                      {c.reward_caps}c / {c.reward_research}rp / {c.reward_rep}rep
                    </Table.Cell>
                    <Table.Cell>{c.expires_s}s</Table.Cell>
                    <Table.Cell>
                      <Button
                        disabled={!data.can_control || !c.complete}
                        onClick={() => act('turnin_contract', { id: c.id })}>
                        Turn In
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}

        {tab === 'Upgrades' && (
          <Section title="District Upgrades">
            <Box mb={1}>
              Tier effects: Industry = bigger material output (with research: plasteel/titanium),
              Logistics = faster supply lines/caravans, Security = more ammo classes and yield.
            </Box>
            {!(data.upgrade_rows && data.upgrade_rows.length) ? (
              <Box color="average">No districts available to upgrade.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>District</Table.Cell>
                  <Table.Cell>Owner</Table.Cell>
                  <Table.Cell>Industry</Table.Cell>
                  <Table.Cell>Logistics</Table.Cell>
                  <Table.Cell>Security</Table.Cell>
                </Table.Row>
                {(data.upgrade_rows || []).map((u) => (
                  <Table.Row key={u.district}>
                    <Table.Cell>{u.district}</Table.Cell>
                    <Table.Cell>{u.owner}</Table.Cell>
                    <Table.Cell>
                      L{u.industry_lvl}{' '}
                      <Button
                        disabled={!data.can_control || !u.is_owned_by_you || !(u.industry_cost > 0)}
                        onClick={() => act('buy_upgrade', { district: u.district, kind: 'industry' })}>
                        Buy ({u.industry_cost})
                      </Button>
                      <Box color="average">{u.industry_next || ''}</Box>
                    </Table.Cell>
                    <Table.Cell>
                      L{u.logistics_lvl}{' '}
                      <Button
                        disabled={!data.can_control || !u.is_owned_by_you || !(u.logistics_cost > 0)}
                        onClick={() => act('buy_upgrade', { district: u.district, kind: 'logistics' })}>
                        Buy ({u.logistics_cost})
                      </Button>
                      <Box color="average">{u.logistics_next || ''}</Box>
                    </Table.Cell>
                    <Table.Cell>
                      L{u.security_lvl}{' '}
                      <Button
                        disabled={!data.can_control || !u.is_owned_by_you || !(u.security_cost > 0)}
                        onClick={() => act('buy_upgrade', { district: u.district, kind: 'security' })}>
                        Buy ({u.security_cost})
                      </Button>
                      <Box color="average">{u.security_next || ''}</Box>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}

        {tab === 'Research' && (
          <Section title="Faction Research Projects">
            <Box mb={1}>
              Raise tier first, then spend research points on projects to specialize your faction.
            </Box>
            {!(data.research_rows && data.research_rows.length) ? (
              <Box color="average">No research projects available.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>Project</Table.Cell>
                  <Table.Cell>Track</Table.Cell>
                  <Table.Cell>Tier</Table.Cell>
                  <Table.Cell>Cost</Table.Cell>
                  <Table.Cell>Effect</Table.Cell>
                  <Table.Cell>Status</Table.Cell>
                  <Table.Cell>Action</Table.Cell>
                </Table.Row>
                {(data.research_rows || []).map((r) => (
                  <Table.Row key={r.id}>
                    <Table.Cell>
                      {r.name}
                      <Box color="average">{r.desc}</Box>
                    </Table.Cell>
                    <Table.Cell>{r.track}</Table.Cell>
                    <Table.Cell>{r.tier}</Table.Cell>
                    <Table.Cell>{r.cost}</Table.Cell>
                    <Table.Cell>{r.effect}</Table.Cell>
                    <Table.Cell>
                      {r.unlocked ? 'Unlocked' : (r.available ? 'Ready' : r.blocked_reason || 'Locked')}
                    </Table.Cell>
                    <Table.Cell>
                      <Button
                        disabled={!data.can_control || r.unlocked || !r.available}
                        onClick={() => act('unlock_research_project', { id: r.id })}>
                        Unlock
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}

        {tab === 'Buildables' && (
          <Section title="Doctrine Buildables">
            <Box mb={1}>
              Template: {data.buildable_template_name || 'None'}
              {data.buildable_template_requires ? ` (requires ${data.buildable_template_requires})` : ''}
            </Box>
            {!(data.buildable_rows && data.buildable_rows.length) ? (
              <Box color="average">No districts available.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>District</Table.Cell>
                  <Table.Cell>Owner</Table.Cell>
                  <Table.Cell>Installed</Table.Cell>
                  <Table.Cell>Action</Table.Cell>
                </Table.Row>
                {(data.buildable_rows || []).map((b) => (
                  <Table.Row key={b.district}>
                    <Table.Cell>{b.district}</Table.Cell>
                    <Table.Cell>{b.owner}</Table.Cell>
                    <Table.Cell>{b.buildable_name || '-'}</Table.Cell>
                    <Table.Cell>
                      <Button
                        disabled={!data.can_control || !b.can_deploy}
                        tooltip={!b.can_deploy ? b.blocked_reason || '' : ''}
                        onClick={() => act('deploy_buildable', { district: b.district })}>
                        Deploy
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}

        {tab === 'Logistics' && (
          <Section title="Caravans & Reputation">
            <Box mb={1}>
              Launch caravan from:
              {(data.rows || [])
                .filter((r) => r.is_owned_by_you)
                .map((r) => (
                  <Button
                    key={r.district}
                    ml={1}
                    disabled={!data.can_control}
                    onClick={() => act('start_caravan', { district: r.district })}>
                    {r.district}
                  </Button>
                ))}
            </Box>
            {!(data.caravans && data.caravans.length) ? (
              <Box color="average">No active caravans for your faction.</Box>
            ) : (
              <Table mb={2}>
                <Table.Row header>
                  <Table.Cell>Faction</Table.Cell>
                  <Table.Cell>Route</Table.Cell>
                  <Table.Cell>ETA</Table.Cell>
                  <Table.Cell>Status</Table.Cell>
                  <Table.Cell>Manifest</Table.Cell>
                  <Table.Cell>Base Reward</Table.Cell>
                </Table.Row>
                {(data.caravans || []).map((c) => (
                  <Table.Row key={c.id}>
                    <Table.Cell>{c.faction || data.faction}</Table.Cell>
                    <Table.Cell>
                      {c.from_district} -> {c.to_district}
                    </Table.Cell>
                    <Table.Cell>{c.eta_s}s</Table.Cell>
                    <Table.Cell>{c.compromised ? 'Compromised' : (c.is_enemy ? 'Tracked' : 'Stable')}</Table.Cell>
                    <Table.Cell>{c.manifest || '-'}</Table.Cell>
                    <Table.Cell>{c.reward_caps}</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
            <Section title="Top Reputation">
              {!(data.top_rep && data.top_rep.length) ? (
                <Box color="average">No recorded reputation entries yet.</Box>
              ) : (
                <Table>
                  <Table.Row header>
                    <Table.Cell>Player</Table.Cell>
                    <Table.Cell>Rep</Table.Cell>
                  </Table.Row>
                  {(data.top_rep || []).map((r) => (
                    <Table.Row key={r.ckey}>
                      <Table.Cell>{r.ckey}</Table.Cell>
                      <Table.Cell>{r.rep}</Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          </Section>
        )}

        {tab === 'Water' && (
          <Section title="Water Rights Network">
            <Box mb={1}>
              District efficiency now depends on water, logistics, and power. Secure purifier nodes and choose share/taxed/restricted policies.
            </Box>
            {!(data.water_rows && data.water_rows.length) ? (
              <Box color="average">No water nodes registered. Place/capture purifier nodes.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>District</Table.Cell>
                  <Table.Cell>Owner</Table.Cell>
                  <Table.Cell>Mode</Table.Cell>
                  <Table.Cell>Output</Table.Cell>
                  <Table.Cell>Status</Table.Cell>
                </Table.Row>
                {(data.water_rows || []).map((w) => (
                  <Table.Row key={w.id}>
                    <Table.Cell>{w.district}</Table.Cell>
                    <Table.Cell>{w.owner}</Table.Cell>
                    <Table.Cell>{w.mode}</Table.Cell>
                    <Table.Cell>{w.output}</Table.Cell>
                    <Table.Cell>{w.operational ? 'ONLINE' : 'OFFLINE'}</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}

        {tab === 'Intel' && (
          <Section title="Intel & Counter-Intel">
            <Box mb={1}>
              Intel points: {data.intel_points || 0} | Route reveal: {data.intel_reveal_s || 0}s
            </Box>
            <Box mb={1}>
              <Button disabled={!data.can_control} onClick={() => act('intel_reveal_routes')}>
                Scan Routes (25)
              </Button>
            </Box>
            <Table>
              <Table.Row header>
                <Table.Cell>District</Table.Cell>
                <Table.Cell>Owner</Table.Cell>
                <Table.Cell>Actions</Table.Cell>
              </Table.Row>
              {(data.rows || []).map((r) => (
                <Table.Row key={`intel-${r.district}`}>
                  <Table.Cell>{r.district}</Table.Cell>
                  <Table.Cell>{r.owner}</Table.Cell>
                  <Table.Cell>
                    <Button
                      disabled={!data.can_control || r.is_owned_by_you}
                      onClick={() => act('intel_jam_district', { district: r.district })}>
                      Jam (35)
                    </Button>
                    <Button
                      disabled={!data.can_control || r.is_owned_by_you}
                      onClick={() => act('intel_fake_distress', { district: r.district })}>
                      Fake Distress (20)
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        )}

        {tab === 'Events' && (
          <Section title="Live Wasteland Events">
            {!(data.events && data.events.length) ? (
              <Box color="average">No live events right now.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>Event</Table.Cell>
                  <Table.Cell>District</Table.Cell>
                  <Table.Cell>Details</Table.Cell>
                  <Table.Cell>Time Left</Table.Cell>
                </Table.Row>
                {(data.events || []).map((e) => (
                  <Table.Row key={e.id}>
                    <Table.Cell>{e.title}</Table.Cell>
                    <Table.Cell>{e.district}</Table.Cell>
                    <Table.Cell>{e.desc}</Table.Cell>
                    <Table.Cell>{e.remaining_s}s</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        )}

        {tab === 'Hazards' && (
          <Section title="Hazard Zone Extraction">
            {!(data.hazard_rows && data.hazard_rows.length) ? (
              <Box color="average">No active hazard windows right now.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>Zone</Table.Cell>
                  <Table.Cell>District</Table.Cell>
                  <Table.Cell>Bonus</Table.Cell>
                  <Table.Cell>Time</Table.Cell>
                  <Table.Cell>Action</Table.Cell>
                </Table.Row>
                {(data.hazard_rows || []).map((h) => {
                  const districtRow = (data.rows || []).find((r) => r.district === h.district);
                  const canExtract = !!districtRow?.is_owned_by_you;
                  return (
                    <Table.Row key={h.id}>
                      <Table.Cell>{h.title}</Table.Cell>
                      <Table.Cell>{h.district}</Table.Cell>
                      <Table.Cell>{h.mult}%</Table.Cell>
                      <Table.Cell>{h.remaining_s}s</Table.Cell>
                      <Table.Cell>
                        <Button
                          disabled={!data.can_control || !canExtract}
                          onClick={() => act('hazard_extract', { district: h.district })}>
                          Extract
                        </Button>
                      </Table.Cell>
                    </Table.Row>
                  );
                })}
              </Table>
            )}
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

export default FactionControl;
