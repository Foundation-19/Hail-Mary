import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, Flex } from '../components';

type EyebotControlData = {
  faction?: string;
  faction_name?: string;
  status?: NetworkStatus;
  patrol_routes?: PatrolRoute[];
  recent_alerts?: Alert[];
};

type NetworkStatus = {
  total_units?: number;
  max_units?: number;
  active_patrols?: number;
  alerts_24h?: number;
  units?: EyebotUnit[];
};

type EyebotUnit = {
  eyebot_id?: string;
  name?: string;
  status?: string;
  mode?: string;
  battery?: number;
  location?: string;
  area?: string;
  patrol_route?: string | null;
  propaganda?: boolean;
};

type PatrolRoute = {
  id?: string;
  name?: string;
  waypoints_count?: number;
  loop_mode?: string;
};

type Alert = {
  eyebot_id?: string;
  target_name?: string;
  target_ckey?: string;
  location?: string;
  time?: number;
};

const batteryColor = (battery: number): string => {
  if (battery > 50) return 'green';
  if (battery > 25) return 'yellow';
  return 'red';
};

export const EyebotControl = (props, context) => {
  const { act, data } = useBackend<EyebotControlData>(context);
  const {
    faction_name,
    status,
    patrol_routes = [],
    recent_alerts = [],
  } = data;

  const units = status?.units || [];
  const totalUnits = status?.total_units || 0;
  const maxUnits = status?.max_units || 5;
  const activePatrols = status?.active_patrols || 0;

  return (
    <Window
      width={650}
      height={700}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title={`> ${faction_name?.toUpperCase() || 'ENCLAVE'}`}>
              <Box color="silver" fontSize="14px">
                ROBCO SURVEILLANCE SYSTEM
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> NETWORK STATUS">
              <LabeledList>
                <LabeledList.Item label="Connected Units">
                  <Box color="silver">{totalUnits}/{maxUnits}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Active Patrols">
                  <Box color="yellow">{activePatrols}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Alerts (24h)">
                  <Box color={recent_alerts.length > 0 ? 'red' : 'green'}>
                    {recent_alerts.length}
                  </Box>
                </LabeledList.Item>
              </LabeledList>
              {totalUnits < maxUnits && (
                <Box mt={2}>
                  <Button
                    color="good"
                    onClick={() => act('spawn_eyebot')}>
                    Deploy New Eyebot
                  </Button>
                </Box>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> ACTIVE UNITS">
              {units.length === 0 ? (
                <Box color="grey" textAlign="center" py={2}>
                  No eyebots connected to network.
                </Box>
              ) : (
                units.map(unit => (
                  <Box key={unit.eyebot_id} mb={2} p={1} backgroundColor="rgba(50,50,50,0.5)">
                    <Flex justify="space-between" align="flex-start">
                      <Flex.Item grow={1}>
                        <Box color={unit.status === 'ONLINE' ? 'green' : 'red'}>
                          {unit.eyebot_id} [{unit.status}]
                        </Box>
                        <Box color="grey" fontSize="12px">
                          Grid {unit.location} | {unit.area}
                        </Box>
                        <Box color="silver" fontSize="12px">
                          Mode: {unit.mode} | Battery: 
                          <Box as="span" color={batteryColor(unit.battery)} ml={1}>
                            {unit.battery}%
                          </Box>
                        </Box>
                        {unit.patrol_route && (
                          <Box color="yellow" fontSize="12px">
                            Route: {unit.patrol_route}
                          </Box>
                        )}
                      </Flex.Item>
                      <Flex.Item>
                        <Stack vertical>
                          <Stack.Item>
                            <Button
                              color="steel"
                              onClick={() => act('view_feed', { eyebot_id: unit.eyebot_id })}>
                              View Feed
                            </Button>
                          </Stack.Item>
                          <Stack.Item>
                            <Button
                              color="good"
                              onClick={() => act('direct_control', { eyebot_id: unit.eyebot_id })}>
                              Direct Control
                            </Button>
                          </Stack.Item>
                          <Stack.Item>
                            <Button
                              color={unit.mode === 'PATROL' ? 'red' : 'yellow'}
                              onClick={() => {
                                if (unit.mode === 'PATROL') {
                                  act('stop_patrol', { eyebot_id: unit.eyebot_id });
                                } else if (patrol_routes.length > 0) {
                                  act('start_patrol', {
                                    eyebot_id: unit.eyebot_id,
                                    route_id: patrol_routes[0].id,
                                  });
                                }
                              }}>
                              {unit.mode === 'PATROL' ? 'Stop Patrol' : 'Start Patrol'}
                            </Button>
                          </Stack.Item>
                          <Stack.Item>
                            <Button
                              color={unit.propaganda ? 'red' : 'good'}
                              onClick={() => act('toggle_propaganda', { eyebot_id: unit.eyebot_id })}>
                              Propaganda: {unit.propaganda ? 'ON' : 'OFF'}
                            </Button>
                          </Stack.Item>
                        </Stack>
                      </Flex.Item>
                    </Flex>
                  </Box>
                ))
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> PATROL ROUTES">
              {patrol_routes.length === 0 ? (
                <Box color="grey" textAlign="center" py={1}>
                  No patrol routes configured.
                </Box>
              ) : (
                patrol_routes.map(route => (
                  <Box key={route.id} mb={1} p={1} backgroundColor="rgba(50,50,50,0.5)">
                    <Flex justify="space-between" align="center">
                      <Flex.Item>
                        <Box color="silver">{route.name}</Box>
                        <Box color="grey" fontSize="12px">
                          {route.waypoints_count} waypoints |
                          Loop: {route.loop_mode}
                        </Box>
                      </Flex.Item>
                    </Flex>
                  </Box>
                ))
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> RECENT ALERTS">
              {recent_alerts.length === 0 ? (
                <Box color="grey" textAlign="center" py={1}>
                  No alerts in the last 24 hours.
                </Box>
              ) : (
                recent_alerts.map((alert, idx) => (
                  <Box key={idx} mb={1} p={1} backgroundColor="rgba(80,30,30,0.5)">
                    <Box color="red">
                      [{alert.eyebot_id}] Detected: {alert.target_name}
                    </Box>
                    <Box color="grey" fontSize="12px">
                      Location: {alert.location}
                    </Box>
                  </Box>
                ))
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
