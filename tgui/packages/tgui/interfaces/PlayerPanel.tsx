import { useBackend, useLocalState } from '../backend';
import { Section, Flex, Stack, Button, Box, Input, NoticeBox, Table } from '../components';
import { Window } from '../layouts';

type PlayerData = {
  ref: string;
  name: string;
  real_name: string;
  key: string;
  job: string;
  ip: string;
  is_antag: boolean;
};

type Data = {
  players: Array<PlayerData>;
};

export const PlayerPanel = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { players } = data;
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');
  const [selectedPlayer, setSelectedPlayer] = useLocalState(context, 'selectedPlayer', null);

  const filteredPlayers = players?.filter(player => 
    !searchText 
    || player.name?.toLowerCase().includes(searchText.toLowerCase())
    || player.key?.toLowerCase().includes(searchText.toLowerCase())
    || player.real_name?.toLowerCase().includes(searchText.toLowerCase())
  ) || [];

  return (
    <Window width={700} height={600} title="ROBCO TERMINAL - PLAYER PANEL" theme="fallout">
      <Window.Content scrollable>
        <Section title="SYSTEM QUERY INTERFACE">
          <Flex align="center" gap={1}>
            <Flex.Item grow>
              <Input
                value={searchText}
                placeholder=">> ENTER SEARCH PARAMETERS..."
                fluid
                onChange={(e, value) => setSearchText(value)}
              />
            </Flex.Item>
            <Flex.Item>
              <Button
                content="CHECK ANTAGONISTS"
                onClick={() => act('check_antagonists')}
              />
            </Flex.Item>
          </Flex>
        </Section>

        <Section title={`CONNECTED USERS: ${filteredPlayers.length}`}>
          <Stack vertical>
            {filteredPlayers.map((player, index) => (
              <Stack.Item key={index}>
                <Box
                  className="PlayerPanel__row"
                  style={{
                    border: '1px solid #3ac83a',
                    padding: '8px',
                    marginBottom: '4px',
                    background: index % 2 === 0 ? 'rgba(10,26,10,0.8)' : 'rgba(18,26,18,0.8)',
                    cursor: 'pointer',
                  }}
                  onClick={() => setSelectedPlayer(
                    selectedPlayer === player.ref ? null : player.ref
                  )}
                >
                  <Flex justify="space-between" align="center">
                    <Flex.Item>
                      <Box as="span" style={{ fontWeight: 'bold' }}>
                        {player.name}
                      </Box>
                      {' - '}
                      <Box as="span" style={{ opacity: 0.8 }}>
                        {player.real_name}
                      </Box>
                      {' - '}
                      <Box as="span" style={{ color: '#6bff6b' }}>
                        {player.key}
                      </Box>
                      {' ('}
                      <Box as="span" style={{ fontStyle: 'italic' }}>
                        {player.job}
                      </Box>
                      {')'}
                      {player.is_antag && (
                        <Box as="span" style={{ color: '#ff6b6b', marginLeft: '10px' }}>
                          [ANTAGONIST]
                        </Box>
                      )}
                    </Flex.Item>
                  </Flex>
                  
                  {selectedPlayer === player.ref && (
                    <Box mt={1} pt={1} style={{ borderTop: '1px solid #3ac83a' }}>
                      <Flex gap={1} wrap>
                        <Button content="[PP]" onClick={() => act('player_opts', { ref: player.ref })} />
                        <Button content="[VV]" onClick={() => act('view_vars', { ref: player.ref })} />
                        <Button content="[PM]" onClick={() => act('priv_msg', { ckey: player.key })} />
                        <Button content="[FLW]" onClick={() => act('follow', { ref: player.ref })} />
                        <Button content="[LOGS]" onClick={() => act('logs', { ref: player.ref })} />
                        <Button content="[TP]" onClick={() => act('traitor', { ref: player.ref })} />
                      </Flex>
                      <Box mt={1} style={{ fontSize: '12px', opacity: 0.7 }}>
                        IP: {player.ip}
                      </Box>
                    </Box>
                  )}
                </Box>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
