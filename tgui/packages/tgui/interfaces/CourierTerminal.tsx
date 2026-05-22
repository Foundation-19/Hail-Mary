import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex } from '../components';
import { Window } from '../layouts';

type CourierTerminalData = {
  available_missions: CourierMission[];
  active_mission: CourierMission | null;
  can_take_mission: boolean;
  courier_reputation: number;
};

type CourierMission = {
  mission_id: string;
  name: string;
  description: string;
  pickup_location: string;
  destination_name: string;
  reward_caps: number;
  bonus_caps: number;
  time_limit: number;
  status: string;
  assigned_to: string | null;
  package_flags: number;
  is_fragile: boolean;
  is_valuable: boolean;
  is_dangerous: boolean;
  is_time_sensitive: boolean;
};

export const CourierTerminal = (props, context) => {
  const { act, data } = useBackend<CourierTerminalData>(context);
  const {
    available_missions = [],
    active_mission,
    can_take_mission,
    courier_reputation,
  } = data;

  const formatTime = (ticks: number): string => {
    const minutes = Math.floor(ticks / 600);
    return `${minutes} min`;
  };

  const getPackageFlags = (mission: CourierMission): string[] => {
    const flags: string[] = [];
    if (mission.is_fragile) flags.push('FRAGILE');
    if (mission.is_valuable) flags.push('VALUABLE');
    if (mission.is_dangerous) flags.push('DANGEROUS');
    if (mission.is_time_sensitive) flags.push('TIME-SENSITIVE');
    return flags;
  };

  const flagColor = (flag: string): string => {
    switch (flag) {
      case 'FRAGILE':
        return '#ffcc00';
      case 'VALUABLE':
        return '#4cff4c';
      case 'DANGEROUS':
        return '#ff4444';
      case 'TIME-SENSITIVE':
        return '#4a90d9';
      default:
        return '#888';
    }
  };

  return (
    <Window width={650} height={600} title="COURIER TERMINAL" theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          MOJAVE DELIVERY SERVICE
          <span style={{ float: 'right' }}>REP: {courier_reputation}</span>
        </Box>

        {active_mission && (
          <Section title="> YOUR ACTIVE DELIVERY">
            <Box
              style={{
                border: '1px solid #4cff4c',
                padding: '12px',
                margin: '8px 0',
                background: '#0a1a0a',
              }}
            >
              <Box style={{ color: '#ffd700', fontWeight: 'bold', marginBottom: '8px' }}>
                {active_mission.name}
              </Box>
              <Box style={{ color: '#b8d4f0', marginBottom: '8px' }}>
                {active_mission.description}
              </Box>
              <Flex wrap style={{ marginBottom: '8px' }}>
                {getPackageFlags(active_mission).map((flag) => (
                  <Box
                    key={flag}
                    style={{
                      color: flagColor(flag),
                      border: `1px solid ${flagColor(flag)}`,
                      padding: '2px 8px',
                      marginRight: '5px',
                      fontSize: '0.85em',
                    }}
                  >
                    {flag}
                  </Box>
                ))}
              </Flex>
              <Box style={{ marginTop: '8px' }}>
                <Box style={{ color: '#ffd700' }}>
                  Reward: {active_mission.reward_caps} caps
                  {active_mission.bonus_caps > 0
                    && ` (+${active_mission.bonus_caps} bonus)`}
                </Box>
                <Box style={{ color: '#4a90d9' }}>
                  From: {active_mission.pickup_location}
                </Box>
                <Box style={{ color: '#4cff4c' }}>
                  To: {active_mission.destination_name}
                </Box>
                {active_mission.time_limit > 0 && (
                  <Box style={{ color: '#ff6666' }}>
                    Time Limit: {formatTime(active_mission.time_limit)}
                  </Box>
                )}
              </Box>
              <Box style={{ marginTop: '10px' }}>
                <Button
                  content="[ABANDON DELIVERY]"
                  color="bad"
                  onClick={() => act('abandon_mission', {
                    mission_id: active_mission.mission_id,
                  })}
                />
              </Box>
            </Box>
          </Section>
        )}

        <Section title="> AVAILABLE DELIVERIES">
          <Button
            content="[REFRESH LIST]"
            onClick={() => act('refresh_missions')}
            style={{ marginBottom: '10px' }}
          />
          {!can_take_mission && !active_mission && (
            <Box
              style={{
                background: '#1a1a0a',
                border: '1px solid #ffcc00',
                padding: '10px',
                marginBottom: '10px',
              }}
            >
              <Box style={{ color: '#ffcc00' }}>
                You already have an active delivery elsewhere.
              </Box>
            </Box>
          )}
          {available_missions.length > 0 ? (
            available_missions.map((mission) => (
              <Box
                key={mission.mission_id}
                style={{
                  border: '1px solid #4a4a4a',
                  padding: '12px',
                  margin: '8px 0',
                  background: '#0a0a0a',
                }}
              >
                <Flex justify="space-between" align="flex-start">
                  <Flex.Item grow={1}>
                    <Box style={{ color: '#d0d0d0', fontWeight: 'bold', marginBottom: '5px' }}>
                      {mission.name}
                    </Box>
                    <Box style={{ color: '#888', fontSize: '0.9em', marginBottom: '8px' }}>
                      {mission.description}
                    </Box>
                    <Flex wrap style={{ marginBottom: '8px' }}>
                      {getPackageFlags(mission).map((flag) => (
                        <Box
                          key={flag}
                          style={{
                            color: flagColor(flag),
                            border: `1px solid ${flagColor(flag)}`,
                            padding: '2px 8px',
                            marginRight: '5px',
                            fontSize: '0.8em',
                          }}
                        >
                          {flag}
                        </Box>
                      ))}
                    </Flex>
                    <Box style={{ marginTop: '8px' }}>
                      <Box style={{ color: '#ffd700' }}>
                        Reward: {mission.reward_caps} caps
                        {mission.bonus_caps > 0
                          && ` (+${mission.bonus_caps} speed bonus)`}
                      </Box>
                      <Box style={{ color: '#4a90d9' }}>
                        Pickup: {mission.pickup_location}
                      </Box>
                      <Box style={{ color: '#4cff4c' }}>
                        Deliver to: {mission.destination_name}
                      </Box>
                      {mission.time_limit > 0 && (
                        <Box style={{ color: '#ff6666' }}>
                          Time Limit: {formatTime(mission.time_limit)}
                        </Box>
                      )}
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    <Button
                      content="[ACCEPT]"
                      color={can_take_mission ? 'good' : 'grey'}
                      disabled={!can_take_mission}
                      onClick={() => act('accept_mission', {
                        mission_id: mission.mission_id,
                      })}
                    />
                  </Flex.Item>
                </Flex>
              </Box>
            ))
          ) : (
            <Box
              style={{
                textAlign: 'center',
                padding: '20px',
                color: '#666',
              }}
            >
              No deliveries available. Check back later.
            </Box>
          )}
        </Section>

        <Section title="> COURIER TIPS">
          <Box style={{ color: '#888', fontSize: '0.9em' }}>
            <Box>&gt; Pick up packages at the designated location.</Box>
            <Box>&gt; Deliver to the drop-off point for payment.</Box>
            <Box>&gt; Speed bonuses for quick deliveries.</Box>
            <Box>&gt; Fragile packages break if thrown!</Box>
            <Box>&gt; Dangerous packages may explode if damaged.</Box>
          </Box>
        </Section>

        <Box className="CharacterSetup__footer">
          MOJAVE EXPRESS - &quot;Neither rain, nor snow, nor death...
        </Box>
      </Window.Content>
    </Window>
  );
};
