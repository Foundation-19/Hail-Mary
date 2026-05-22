import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, Dropdown, Flex } from '../components';

type VertibirdControlData = {
  faction: string;
  faction_name: string;
  vertibird_status: string;
  vertibird_fuel: number;
  vertibird_max_fuel: number;
  vertibird_health: number;
  vertibird_max_health: number;
  minigun_ammo: number;
  minigun_max: number;
  missiles: number;
  missiles_max: number;
  callsign: string;
  in_mission: boolean;
  cooldown: number;
  destinations: Destination[];
  active_beacons: Beacon[];
};

type Destination = {
  name: string;
  x: number;
  y: number;
  z: number;
  travel_time: number;
};

type Beacon = {
  name: string;
  ckey: string;
  x: number;
  y: number;
  z: number;
};

const fuelPercent = (fuel: number, max: number): number => {
  return Math.round((fuel / max) * 100);
};

const healthColor = (health: number, max: number): string => {
  const pct = health / max;
  if (pct > 0.75) return 'green';
  if (pct > 0.5) return 'yellow';
  if (pct > 0.25) return 'orange';
  return 'red';
};

export const VertibirdControl = (props, context) => {
  const { act, data } = useBackend<VertibirdControlData>(context);
  const {
    faction_name,
    vertibird_status,
    vertibird_fuel = 0,
    vertibird_max_fuel = 100,
    vertibird_health = 500,
    vertibird_max_health = 500,
    minigun_ammo = 0,
    minigun_max = 500,
    missiles = 0,
    missiles_max = 8,
    callsign,
    in_mission,
    cooldown,
    destinations = [],
    active_beacons = [],
  } = data;

  const [selectedCrate, setSelectedCrate] = useLocalState(context, 'selectedCrate', 'ammunition');

  const crateTypes = [
    { display: 'Ammunition', value: 'ammunition' },
    { display: 'Medical', value: 'medical' },
    { display: 'Equipment', value: 'equipment' },
    { display: 'Emergency', value: 'emergency' },
  ];

  return (
    <Window
      width={600}
      height={700}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title={`> ${faction_name?.toUpperCase() || 'ENCLAVE'}`}>
              <Box color="silver" fontSize="14px">
                ROBCO AIRCRAFT MANAGEMENT SYSTEM
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> VERTIBIRD STATUS">
              <LabeledList>
                <LabeledList.Item label="Callsign">
                  <Box color="gold" bold>{callsign || 'EV-101 "Liberty"'}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Status">
                  <Box color={in_mission ? 'yellow' : 'green'}>
                    {in_mission ? 'IN MISSION' : vertibird_status?.toUpperCase() || 'STANDBY'}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Fuel">
                  <Box color="silver">
                    {vertibird_fuel}/{vertibird_max_fuel}
                    ({fuelPercent(vertibird_fuel, vertibird_max_fuel)}%)
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Hull Integrity">
                  <Box
                    color={healthColor(
                      vertibird_health,
                      vertibird_max_health
                    )}>
                    {vertibird_health}/{vertibird_max_health}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Minigun Ammo">
                  <Box color="silver">{minigun_ammo}/{minigun_max}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Missiles">
                  <Box color="silver">{missiles}/{missiles_max}</Box>
                </LabeledList.Item>
                {cooldown > 0 && (
                  <LabeledList.Item label="Cooldown">
                    <Box color="red">{cooldown}s remaining</Box>
                  </LabeledList.Item>
                )}
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> TRANSPORT MISSION">
              {destinations.length === 0 ? (
                <Box color="grey" textAlign="center" py={1}>
                  No destinations available.
                </Box>
              ) : (
                <>
                  <Box mb={1} color="grey">
                    Select destination:
                  </Box>
                  {destinations.map(dest => (
                    <Box key={`${dest.x}-${dest.y}-${dest.z}`} mb={1} p={1} backgroundColor="rgba(50,50,50,0.5)">
                      <Flex justify="space-between" align="center">
                        <Flex.Item>
                          <Box color="silver">{dest.name}</Box>
                          <Box color="grey" fontSize="12px">Travel time: {dest.travel_time}s</Box>
                        </Flex.Item>
                        <Flex.Item>
                          <Button
                            color={in_mission || cooldown > 0 ? 'grey' : 'good'}
                            disabled={in_mission || cooldown > 0}
                            onClick={() => act('transport', { x: dest.x, y: dest.y, z: dest.z })}>
                            Launch
                          </Button>
                        </Flex.Item>
                      </Flex>
                    </Box>
                  ))}
                </>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> SUPPLY DROP">
              {active_beacons.length === 0 ? (
                <Box color="grey" textAlign="center" py={1}>
                  No active beacons detected.
                </Box>
              ) : (
                <>
                  <Box mb={1}>
                    <Box color="grey" mb={1}>Crate Type:</Box>
                    <Dropdown
                      options={crateTypes}
                      selected={selectedCrate}
                      onSelected={(val) => setSelectedCrate(val)}
                    />
                  </Box>
                  {active_beacons.map((beacon, idx) => (
                    <Box key={idx} mb={1} p={1} backgroundColor="rgba(50,50,50,0.5)">
                      <Flex justify="space-between" align="center">
                        <Flex.Item>
                          <Box color="green">Beacon Active</Box>
                          <Box color="grey" fontSize="12px">
                            Grid {beacon.x},{beacon.y} ({beacon.ckey})
                          </Box>
                        </Flex.Item>
                        <Flex.Item>
                          <Button
                            color={in_mission || cooldown > 0 ? 'grey' : 'good'}
                            disabled={in_mission || cooldown > 0}
                            onClick={() => act('supply_drop', {
                              beacon: idx,
                              crate_type: selectedCrate,
                            })}>
                            Drop
                          </Button>
                        </Flex.Item>
                      </Flex>
                    </Box>
                  ))}
                </>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> EXTRACTION">
              {active_beacons.length === 0 ? (
                <Box color="grey" textAlign="center" py={1}>
                  No extraction requests.
                </Box>
              ) : (
                active_beacons.map((beacon, idx) => (
                  <Box key={idx} mb={1} p={1} backgroundColor="rgba(50,50,50,0.5)">
                    <Flex justify="space-between" align="center">
                      <Flex.Item>
                        <Box color="red">Extraction Requested</Box>
                        <Box color="grey" fontSize="12px">
                          Grid {beacon.x},{beacon.y} ({beacon.ckey})
                        </Box>
                      </Flex.Item>
                      <Flex.Item>
                        <Button
                          color={in_mission || cooldown > 0 ? 'grey' : 'good'}
                          disabled={in_mission || cooldown > 0}
                          onClick={() => act('extraction', { beacon: idx })}>
                          Send
                        </Button>
                      </Flex.Item>
                    </Flex>
                  </Box>
                ))
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section>
              <Button
                color="steel"
                onClick={() => act('reload')}>
                Refresh Status
              </Button>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
