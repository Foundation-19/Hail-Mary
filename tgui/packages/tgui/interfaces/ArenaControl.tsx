import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, Flex } from '../components';

type ArenaControlData = {
  match_active: boolean;
  match_type: number;
  match_type_name: string;
  total_bets_red: number;
  total_bets_blue: number;
  odds_red: number;
  odds_blue: number;
  winner_team: string;
  red_team: FighterData[];
  blue_team: FighterData[];
  match_history: MatchHistoryEntry[];
  is_arena_master: boolean;
};

type FighterData = {
  fighter_ckey: string;
  fighter_name: string;
  wins: number;
  losses: number;
  is_slave: boolean;
};

type MatchHistoryEntry = {
  match_id: string;
  match_type: number;
  winner_team: string;
  red_fighters: string;
  blue_fighters: string;
  total_bets: number;
};

const matchTypes = [
  { id: 1, name: 'Deathmatch' },
  { id: 2, name: 'Submission' },
  { id: 3, name: 'Team Battle' },
  { id: 4, name: 'Beast Fight' },
];

export const ArenaControl = (props, context) => {
  const { act, data } = useBackend<ArenaControlData>(context);
  const {
    match_active,
    match_type,
    match_type_name,
    total_bets_red,
    total_bets_blue,
    odds_red,
    odds_blue,
    winner_team,
    red_team = [],
    blue_team = [],
    match_history = [],
    is_arena_master,
  } = data;

  const [betAmount, setBetAmount] = useLocalState(context, 'betAmount', 100);
  const [betTeam, setBetTeam] = useLocalState(context, 'betTeam', 'red');

  return (
    <Window
      width={650}
      height={700}
      title="LEGION ARENA"
      theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          LEGION ARENA
          <span style={{ float: 'right' }}>MARE IMPERATOR</span>
        </Box>

        <Section title="> CURRENT MATCH">
          <Stack>
            <Stack.Item grow>
              <Box color={match_active ? 'yellow' : 'grey'} fontSize="16px">
                Status: {match_active ? 'IN PROGRESS' : 'WAITING'}
              </Box>
              <Box color="silver" mt={1}>
                Type: {match_type_name}
              </Box>
            </Stack.Item>
            {is_arena_master && !match_active && (
              <Stack.Item>
                <Flex wrap>
                  {matchTypes.map(type => (
                    <Flex.Item key={type.id} mr={1}>
                      <Button
                        selected={match_type === type.id}
                        onClick={() => act('set_match_type', { match_type: type.id })}>
                        {type.name}
                      </Button>
                    </Flex.Item>
                  ))}
                </Flex>
              </Stack.Item>
            )}
          </Stack>
        </Section>

        <Stack>
          <Stack.Item grow basis="48%">
            <Section title="> RED TEAM">
              {red_team.length === 0 ? (
                <Box color="grey" textAlign="center" py={2}>
                  No fighters registered
                </Box>
              ) : (
                red_team.map(fighter => (
                  <Box key={fighter.fighter_ckey} mb={1} p={1} backgroundColor="rgba(50,20,20,0.5)">
                    <Box color="red">{fighter.fighter_name}</Box>
                    <Box color="grey" fontSize="12px">
                      W: {fighter.wins} L: {fighter.losses}
                      {fighter.is_slave && ' (Slave)'}
                    </Box>
                    {is_arena_master && !match_active && (
                      <Button
                        color="bad"
                        onClick={() => act('remove_fighter', { team: 'red', fighter_id: fighter.fighter_ckey })}>
                        Remove
                      </Button>
                    )}
                  </Box>
                ))
              )}
              {!match_active && (
                <Button
                  color="red"
                  mt={1}
                  onClick={() => act('register_fighter', { team: 'red' })}>
                  Register Yourself
                </Button>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item grow basis="48%">
            <Section title="> BLUE TEAM">
              {blue_team.length === 0 ? (
                <Box color="grey" textAlign="center" py={2}>
                  No fighters registered
                </Box>
              ) : (
                blue_team.map(fighter => (
                  <Box key={fighter.fighter_ckey} mb={1} p={1} backgroundColor="rgba(20,20,50,0.5)">
                    <Box color="blue">{fighter.fighter_name}</Box>
                    <Box color="grey" fontSize="12px">
                      W: {fighter.wins} L: {fighter.losses}
                      {fighter.is_slave && ' (Slave)'}
                    </Box>
                    {is_arena_master && !match_active && (
                      <Button
                        color="bad"
                        onClick={() => act('remove_fighter', { team: 'blue', fighter_id: fighter.fighter_ckey })}>
                        Remove
                      </Button>
                    )}
                  </Box>
                ))
              )}
              {!match_active && (
                <Button
                  color="blue"
                  mt={1}
                  onClick={() => act('register_fighter', { team: 'blue' })}>
                  Register Yourself
                </Button>
              )}
            </Section>
          </Stack.Item>
        </Stack>

        <Section title="> BETTING">
          <Stack>
            <Stack.Item grow>
              <Box color="red">Red: {total_bets_red} caps ({odds_red}x)</Box>
              <Box color="blue">Blue: {total_bets_blue} caps ({odds_blue}x)</Box>
            </Stack.Item>
          </Stack>
          {!match_active && (
            <Flex mt={2} align="center">
              <Flex.Item>
                <Button
                  color={betTeam === 'red' ? 'red' : 'grey'}
                  onClick={() => setBetTeam('red')}>
                  Red
                </Button>
                <Button
                  color={betTeam === 'blue' ? 'blue' : 'grey'}
                  onClick={() => setBetTeam('blue')}>
                  Blue
                </Button>
              </Flex.Item>
              <Flex.Item ml={2}>
                <Button
                  onClick={() => setBetAmount(Math.max(10, betAmount - 50))}>
                  -
                </Button>
                <Box as="span" mx={1}>{betAmount} caps</Box>
                <Button
                  onClick={() => setBetAmount(Math.min(500, betAmount + 50))}>
                  +
                </Button>
              </Flex.Item>
              <Flex.Item ml={2}>
                <Button
                  color="gold"
                  onClick={() => act('place_bet', { team: betTeam, amount: betAmount })}>
                  Place Bet
                </Button>
              </Flex.Item>
            </Flex>
          )}
        </Section>

        {is_arena_master && (
          <Section title="> ARENA CONTROLS">
            <Flex wrap gap={1}>
              {!match_active ? (
                <Button
                  color="good"
                  disabled={red_team.length < 1 || blue_team.length < 1}
                  onClick={() => act('start_match')}>
                  Start Match
                </Button>
              ) : (
                <>
                  <Button
                    color="red"
                    onClick={() => act('end_match', { winner: 'red' })}>
                    Red Wins
                  </Button>
                  <Button
                    color="blue"
                    onClick={() => act('end_match', { winner: 'blue' })}>
                    Blue Wins
                  </Button>
                  <Button
                    color="bad"
                    onClick={() => act('end_match', { winner: 'draw' })}>
                    Draw
                  </Button>
                </>
              )}
              <Button
                color="bad"
                onClick={() => act('reset_arena')}>
                Reset Arena
              </Button>
            </Flex>
          </Section>
        )}

        <Section title="> MATCH HISTORY">
          {match_history.length === 0 ? (
            <Box color="grey" textAlign="center" py={2}>
              No matches recorded
            </Box>
          ) : (
            match_history.map((match, idx) => (
              <Box key={idx} mb={1} p={1} backgroundColor="rgba(30,30,30,0.5)">
                <Flex justify="space-between">
                  <Flex.Item>
                    <Box color="silver">
                      {match.winner_team === 'red' ? 'Red' : match.winner_team === 'blue' ? 'Blue' : 'Draw'}
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    <Box color="grey" fontSize="12px">
                      Bets: {match.total_bets} caps
                    </Box>
                  </Flex.Item>
                </Flex>
                <Box color="grey" fontSize="12px">
                  {match.red_fighters} vs {match.blue_fighters}
                </Box>
              </Box>
            ))
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
