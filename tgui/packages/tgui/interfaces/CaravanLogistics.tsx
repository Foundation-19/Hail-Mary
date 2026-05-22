import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, ProgressBar } from '../components';
import { Window } from '../layouts';

type CaravanLogisticsData = {
  is_quartermaster: boolean;
  can_deploy: boolean;
  routes: Route[];
  active_caravans: Caravan[];
  stats: Stats;
  my_escorts: Caravan[];
};

type Route = {
  id: string;
  name: string;
  description: string;
  danger_level: number;
  min_guards: number;
  caps_per_run: number;
  supplies_per_run: number;
  status: string;
  active_caravan: string | null;
};

type Caravan = {
  id: string;
  name: string;
  route_id: string;
  route_name: string;
  status: string;
  progress: number;
  guards: string[];
  cargo: string[];
  caps_earned: number;
  supplies_delivered: number;
  integrity: number;
  max_integrity: number;
};

type Stats = {
  runs_today: number;
  revenue: number;
  supplies_delivered: number;
  losses: number;
};

const dangerStars = (level: number): string => {
  return '★'.repeat(level) + '☆'.repeat(5 - level);
};

const statusColor = (status: string): string => {
  switch (status) {
    case 'traveling':
      return '#4a90d9';
    case 'under_attack':
      return '#ff4444';
    case 'arrived':
      return '#44ff44';
    case 'docked':
    case 'loading':
      return '#888';
    default:
      return '#b8d4f0';
  }
};

const routeStatusColor = (status: string): string => {
  switch (status) {
    case 'active':
      return '#4a90d9';
    case 'damaged':
      return '#ff8800';
    case 'blocked':
      return '#ff4444';
    default:
      return '#888';
  }
};

export const CaravanLogistics = (props, context) => {
  const { act, data } = useBackend<CaravanLogisticsData>(context);
  const {
    is_quartermaster,
    can_deploy,
    routes = [],
    active_caravans = [],
    stats,
    my_escorts = [],
  } = data;

  const [selectedRoute, setSelectedRoute] = useLocalState<string>(
    context,
    'selectedRoute',
    ''
  );

  return (
    <Window width={700} height={650} title="NCR CARAVAN LOGISTICS" theme="ncr">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          NEW CALIFORNIA REPUBLIC
          <span style={{ float: 'right' }}>SUPPLY DEPOT</span>
        </Box>

        {my_escorts.length > 0 && (
          <Section title="> YOUR ESCORT MISSIONS">
            {my_escorts.map((caravan) => (
              <Box
                key={caravan.id}
                style={{
                  border: '1px solid #2d5a87',
                  padding: '12px',
                  margin: '8px 0',
                  background: '#0a0f1a',
                }}
              >
                <Flex justify="space-between" align="center">
                  <Flex.Item>
                    <Box style={{ color: '#ffd700', fontWeight: 'bold' }}>
                      {caravan.route_name}
                    </Box>
                    <Box
                      style={{
                        color: statusColor(caravan.status),
                        marginTop: '5px',
                      }}
                    >
                      Status: {caravan.status.toUpperCase()}
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    {caravan.status === 'traveling' && (
                      <Button
                        content="[CANCEL ESCORT]"
                        color="bad"
                        onClick={() => act('cancel_escort', {
                          caravan_id: caravan.id,
                        })}
                      />
                    )}
                  </Flex.Item>
                </Flex>
                {caravan.status === 'traveling' && (
                  <Box style={{ marginTop: '10px' }}>
                    <ProgressBar
                      value={caravan.progress / 100}
                      color="#4a90d9"
                      style={{ height: '20px' }}
                    >
                      {Math.round(caravan.progress)}% Complete
                    </ProgressBar>
                  </Box>
                )}
              </Box>
            ))}
          </Section>
        )}

        <Section title="> ACTIVE CARAVANS">
          {active_caravans.length > 0 ? (
            active_caravans.map((caravan) => (
              <Box
                key={caravan.id}
                style={{
                  border: '1px solid #2d5a87',
                  padding: '12px',
                  margin: '8px 0',
                  background:
                    caravan.status === 'under_attack' ? '#1a0a0a' : '#0a0f1a',
                }}
              >
                <Flex justify="space-between" align="flex-start">
                  <Flex.Item grow={1}>
                    <Box style={{ color: '#ffd700', fontWeight: 'bold' }}>
                      {caravan.route_name}
                    </Box>
                    <Box
                      style={{
                        color: statusColor(caravan.status),
                        marginTop: '5px',
                      }}
                    >
                      Status: {caravan.status.toUpperCase()}
                    </Box>
                    <Box style={{ color: '#b8d4f0', marginTop: '5px' }}>
                      Guards: {caravan.guards.length} / 4
                    </Box>
                    <Box style={{ color: '#4a90d9', marginTop: '5px' }}>
                      Cargo: {caravan.caps_earned} caps,{' '}
                      {caravan.supplies_delivered} supplies
                    </Box>
                    <Box
                      style={{
                        color:
                          caravan.integrity < 50 ? '#ff4444' : '#44ff44',
                        marginTop: '5px',
                      }}
                    >
                      Integrity: {caravan.integrity}/{caravan.max_integrity}
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    {caravan.status === 'traveling' && is_quartermaster && (
                      <Button
                        content="[RECALL]"
                        color="bad"
                        onClick={() => act('recall_caravan', {
                          caravan_id: caravan.id,
                        })}
                      />
                    )}
                    {caravan.status === 'traveling'
                      && !caravan.guards.includes('current_user') && (
                      <Button
                        content="[JOIN ESCORT]"
                        onClick={() => act('sign_up_escort', {
                          route_id: caravan.route_id,
                        })}
                      />
                    )}
                  </Flex.Item>
                </Flex>
                {caravan.status === 'traveling' && (
                  <Box style={{ marginTop: '10px' }}>
                    <ProgressBar
                      value={caravan.progress / 100}
                      color="#4a90d9"
                      style={{ height: '20px' }}
                    >
                      {Math.round(caravan.progress)}% Complete
                    </ProgressBar>
                  </Box>
                )}
                {caravan.status === 'under_attack' && (
                  <Box
                    style={{
                      color: '#ff4444',
                      marginTop: '10px',
                      fontWeight: 'bold',
                    }}
                  >
                    CARAVAN UNDER ATTACK - ASSIST IMMEDIATELY
                  </Box>
                )}
              </Box>
            ))
          ) : (
            <Box
              style={{
                textAlign: 'center',
                padding: '20px',
                color: '#2a5a87',
              }}
            >
              No active caravans.
            </Box>
          )}
        </Section>

        <Section title="> AVAILABLE ROUTES">
          {routes.map((route) => (
            <Box
              key={route.id}
              style={{
                border: '1px solid #2d5a87',
                padding: '12px',
                margin: '8px 0',
                background:
                  route.status === 'active' ? '#0a1a2a' : '#0a0f1a',
                opacity: route.status === 'active' ? 0.7 : 1,
              }}
            >
              <Flex justify="space-between" align="flex-start">
                <Flex.Item grow={1}>
                  <Box
                    style={{
                      color: routeStatusColor(route.status),
                      fontWeight: 'bold',
                    }}
                  >
                    {route.name}
                  </Box>
                  <Box
                    style={{
                      color: '#b8d4f0',
                      marginTop: '5px',
                      fontSize: '0.9em',
                    }}
                  >
                    {route.description}
                  </Box>
                  <Box style={{ marginTop: '8px' }}>
                    <Box style={{ color: '#ffd700' }}>
                      Reward: {route.caps_per_run} caps
                    </Box>
                    <Box style={{ color: '#4a90d9' }}>
                      Danger: {dangerStars(route.danger_level)}
                    </Box>
                    <Box style={{ color: '#888' }}>
                      Min Guards: {route.min_guards}
                    </Box>
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  {route.status === 'inactive' && can_deploy && (
                    <Button
                      content="[DEPLOY]"
                      color="good"
                      onClick={() => {
                        setSelectedRoute(route.id);
                        act('deploy_caravan', {
                          route_id: route.id,
                          guards: [],
                        });
                      }}
                    />
                  )}
                  {route.status === 'active' && (
                    <Box style={{ color: '#4cff4c' }}>IN TRANSIT</Box>
                  )}
                  {route.status === 'damaged' && (
                    <Box style={{ color: '#ff8800' }}>DAMAGED</Box>
                  )}
                </Flex.Item>
              </Flex>
            </Box>
          ))}
        </Section>

        <Section title="> ECONOMY STATS">
          <Flex wrap="wrap">
            <Flex.Item
              style={{
                width: '48%',
                padding: '8px',
                background: '#0a1520',
                margin: '2px',
              }}
            >
              <Box style={{ color: '#888', fontSize: '0.85em' }}>
                Runs Today
              </Box>
              <Box style={{ color: '#ffd700', fontSize: '1.2em' }}>
                {stats.runs_today}
              </Box>
            </Flex.Item>
            <Flex.Item
              style={{
                width: '48%',
                padding: '8px',
                background: '#0a1520',
                margin: '2px',
              }}
            >
              <Box style={{ color: '#888', fontSize: '0.85em' }}>
                Revenue
              </Box>
              <Box style={{ color: '#ffd700', fontSize: '1.2em' }}>
                {stats.revenue} caps
              </Box>
            </Flex.Item>
            <Flex.Item
              style={{
                width: '48%',
                padding: '8px',
                background: '#0a1520',
                margin: '2px',
              }}
            >
              <Box style={{ color: '#888', fontSize: '0.85em' }}>
                Supplies Delivered
              </Box>
              <Box style={{ color: '#4a90d9', fontSize: '1.2em' }}>
                {stats.supplies_delivered} units
              </Box>
            </Flex.Item>
            <Flex.Item
              style={{
                width: '48%',
                padding: '8px',
                background: '#0a1520',
                margin: '2px',
              }}
            >
              <Box style={{ color: '#888', fontSize: '0.85em' }}>
                Losses
              </Box>
              <Box style={{ color: '#ff4444', fontSize: '1.2em' }}>
                {stats.losses} caravan(s)
              </Box>
            </Flex.Item>
          </Flex>
        </Section>

        <Box className="CharacterSetup__footer">
          NEW CALIFORNIA REPUBLIC - LOGISTICS DIVISION
        </Box>
      </Window.Content>
    </Window>
  );
};
