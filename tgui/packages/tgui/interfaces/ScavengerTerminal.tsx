import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex } from '../components';
import { Window } from '../layouts';

type ScavengerTerminalData = {
  available_hunts: ScavengerHunt[];
  active_hunt: ScavengerHunt | null;
  can_start_hunt: boolean;
  total_found: number;
};

type ScavengerHunt = {
  hunt_id: string;
  name: string;
  description: string;
  reward_caps: number;
  reward_item: string;
  time_limit: number;
  status: string;
  required_items: number;
  found_items: number;
  difficulty: number;
  hint: string;
};

const difficultyStars = (level: number): string => {
  return '★'.repeat(level) + '☆'.repeat(3 - level);
};

const difficultyColor = (level: number): string => {
  switch (level) {
    case 1:
      return '#4cff4c';
    case 2:
      return '#ffcc00';
    case 3:
      return '#ff4444';
    default:
      return '#888';
  }
};

export const ScavengerTerminal = (props, context) => {
  const { act, data } = useBackend<ScavengerTerminalData>(context);
  const {
    available_hunts = [],
    active_hunt,
    can_start_hunt,
    total_found,
  } = data;

  const formatTime = (ticks: number): string => {
    const minutes = Math.floor(ticks / 600);
    return `${minutes} min`;
  };

  return (
    <Window width={600} height={550} title="SCAVENGER TERMINAL" theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          WASTELAND TREASURE HUNTS
          <span style={{ float: 'right' }}>FOUND: {total_found}</span>
        </Box>

        {active_hunt && (
          <Section title="> YOUR ACTIVE HUNT">
            <Box
              style={{
                border: `1px solid ${difficultyColor(active_hunt.difficulty)}`,
                padding: '12px',
                margin: '8px 0',
                background: '#0a0a0a',
              }}
            >
              <Flex justify="space-between" align="flex-start">
                <Flex.Item grow={1}>
                  <Box
                    style={{
                      color: difficultyColor(active_hunt.difficulty),
                      fontWeight: 'bold',
                      marginBottom: '5px',
                    }}
                  >
                    {active_hunt.name}
                  </Box>
                  <Box style={{ color: '#888', marginBottom: '8px' }}>
                    {active_hunt.description}
                  </Box>
                  <Box
                    style={{
                      background: '#1a1a1a',
                      padding: '10px',
                      borderRadius: '3px',
                      marginBottom: '8px',
                    }}
                  >
                    <Box style={{ color: '#4cff4c', fontWeight: 'bold' }}>
                      PROGRESS: {active_hunt.found_items}/
                      {active_hunt.required_items} items found
                    </Box>
                    <Box
                      style={{
                        background: '#333',
                        height: '10px',
                        borderRadius: '5px',
                        marginTop: '5px',
                        overflow: 'hidden',
                      }}
                    >
                      <Box
                        style={{
                          background: '#4cff4c',
                          height: '100%',
                          width: `${
                            (active_hunt.found_items
                              / active_hunt.required_items)
                            * 100
                          }%`,
                        }}
                      />
                    </Box>
                  </Box>
                  {active_hunt.hint && (
                    <Box style={{ color: '#4a90d9', marginBottom: '8px' }}>
                      Hint: {active_hunt.hint}
                    </Box>
                  )}
                  {active_hunt.time_limit > 0 && (
                    <Box style={{ color: '#ff6666' }}>
                      Time Limit: {formatTime(active_hunt.time_limit)}
                    </Box>
                  )}
                </Flex.Item>
              </Flex>
              <Box style={{ marginTop: '10px' }}>
                <Button
                  content="[ABANDON HUNT]"
                  color="bad"
                  onClick={() => act('abandon_hunt', {
                    hunt_id: active_hunt.hunt_id,
                  })}
                />
              </Box>
            </Box>
          </Section>
        )}

        <Section title="> AVAILABLE HUNTS">
          <Button
            content="[REFRESH HUNTS]"
            onClick={() => act('refresh_hunts')}
            style={{ marginBottom: '10px' }}
          />
          {!can_start_hunt && !active_hunt && (
            <Box
              style={{
                background: '#1a1a0a',
                border: '1px solid #ffcc00',
                padding: '10px',
                marginBottom: '10px',
              }}
            >
              <Box style={{ color: '#ffcc00' }}>
                You already have an active hunt.
              </Box>
            </Box>
          )}
          {available_hunts.length > 0 ? (
            available_hunts.map((hunt) => (
              <Box
                key={hunt.hunt_id}
                style={{
                  border: `1px solid ${difficultyColor(hunt.difficulty)}`,
                  padding: '12px',
                  margin: '8px 0',
                  background: '#0a0a0a',
                }}
              >
                <Flex justify="space-between" align="flex-start">
                  <Flex.Item grow={1}>
                    <Box
                      style={{
                        color: difficultyColor(hunt.difficulty),
                        fontWeight: 'bold',
                        marginBottom: '5px',
                      }}
                    >
                      {hunt.name}
                    </Box>
                    <Box style={{ color: '#888', fontSize: '0.9em', marginBottom: '8px' }}>
                      {hunt.description}
                    </Box>
                    <Box style={{ marginTop: '8px' }}>
                      <Box style={{ color: '#ffd700' }}>
                        Reward: {hunt.reward_caps} caps
                      </Box>
                      {hunt.reward_item && (
                        <Box style={{ color: '#4cff4c' }}>
                          Bonus: {hunt.reward_item}
                        </Box>
                      )}
                      <Box style={{ color: '#b8d4f0' }}>
                        Items to find: {hunt.required_items}
                      </Box>
                      <Box style={{ color: difficultyColor(hunt.difficulty) }}>
                        Difficulty: {difficultyStars(hunt.difficulty)}
                      </Box>
                      {hunt.time_limit > 0 && (
                        <Box style={{ color: '#ff6666' }}>
                          Time Limit: {formatTime(hunt.time_limit)}
                        </Box>
                      )}
                    </Box>
                    {hunt.hint && (
                      <Box
                        style={{
                          color: '#4a90d9',
                          marginTop: '8px',
                          fontStyle: 'italic',
                        }}
                      >
                        &quot;{hunt.hint}&quot;
                      </Box>
                    )}
                  </Flex.Item>
                  <Flex.Item>
                    <Button
                      content="[START]"
                      color={can_start_hunt ? 'good' : 'grey'}
                      disabled={!can_start_hunt}
                      onClick={() => act('start_hunt', {
                        hunt_id: hunt.hunt_id,
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
              No hunts available. Check back later.
            </Box>
          )}
        </Section>

        <Section title="> HUNTING TIPS">
          <Box style={{ color: '#888', fontSize: '0.9em' }}>
            <Box>&gt; Tokens are scattered across the wasteland.</Box>
            <Box>&gt; Higher difficulty = better rewards.</Box>
            <Box>&gt; Use hints to narrow your search area.</Box>
            <Box>&gt; Tokens are color-coded by rarity.</Box>
            <Box>&gt; Abandoning causes tokens to vanish.</Box>
          </Box>
        </Section>

        <Box className="CharacterSetup__footer">
          TREASURE HUNTERS GUILD
        </Box>
      </Window.Content>
    </Window>
  );
};
