import { useBackend, useLocalState } from '../backend';
/* eslint-disable max-len */
import { Box, Button, Section, Flex, Divider } from '../components';
import { Window } from '../layouts';

type PerkMenuData = {
  points: number;
  perks: PerkInfo[];
  active_perks: string[];
  special_stats: string[];
  current_filter: string;
};

type PerkInfo = {
  id: string;
  name: string;
  desc: string;
  special_stat: string;
  special_min: number;
  user_stat: number;
  requires_perk: string;
  requires_perk_name: string;
  has_prereq: boolean;
  can_unlock: boolean;
  is_active: boolean;
};

export const PerkMenu = (props, context) => {
  const { act, data } = useBackend<PerkMenuData>(context);
  const {
    points = 0,
    perks = [],
    active_perks = [],
    special_stats = [],
    current_filter = 'all',
  } = data;

  const [filter, setFilter] = useLocalState(context, 'filter', current_filter);

  const filteredPerks = filter === 'all'
    ? perks
    : perks.filter(p => p.special_stat === filter);

  return (
    <Window width={800} height={700} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
          <span style={{ float: 'right' }}>VAULT-TEC CORP</span>
        </Box>

        <Section>
          <Box style={{ textAlign: 'center' }}>
            <Box style={{ fontSize: '2em', color: '#ffaa00', fontWeight: 'bold' }}>{points}</Box>
            <Box style={{ color: '#2a7a52' }}>Perk Points Available</Box>
          </Box>
        </Section>

        <Section title="> FILTER BY SPECIAL">
          <Flex wrap>
            {special_stats.map(stat => (
              <Flex.Item key={stat}>
                <Button
                  content={stat}
                  selected={filter === stat}
                  onClick={() => setFilter(stat)}
                  style={{ margin: '2px' }}
                />
              </Flex.Item>
            ))}
            <Flex.Item>
              <Button
                content="ALL"
                selected={filter === 'all'}
                onClick={() => setFilter('all')}
                style={{ margin: '2px' }}
              />
            </Flex.Item>
          </Flex>
        </Section>

        <Section title={`> PERKS (${filteredPerks.length})`}>
          <Flex wrap>
            {filteredPerks.map(perk => (
              <Flex.Item
                key={perk.id}
                basis="50%"
                style={{ padding: '5px' }}
              >
                <Box
                  style={{
                    border: perk.is_active ? '2px solid #4cff4c' : '1px solid #1a5e38',
                    padding: '12px',
                    background: perk.is_active ? 'rgba(76,255,76,0.1)' : '#041a0e',
                    height: '100%',
                  }}
                >
                  <Box style={{ color: '#ffaa00', fontWeight: 'bold' }}>{perk.name}</Box>
                  <Box style={{ color: '#2a7a52', fontSize: '0.9em', margin: '8px 0' }}>{perk.desc}</Box>
                  
                  {perk.is_active ? (
                    <Box style={{ color: '#4cff4c', fontWeight: 'bold' }}>UNLOCKED</Box>
                  ) : (
                    <>
                      <Box style={{ color: perk.user_stat >= perk.special_min ? '#4cff4c' : '#ff3333', fontSize: '0.85em' }}>
                        {perk.special_stat} {perk.special_min} (You: {perk.user_stat})
                      </Box>
                      {perk.requires_perk && (
                        <Box style={{ color: perk.has_prereq ? '#4cff4c' : '#ff3333', fontSize: '0.85em' }}>
                          Requires: {perk.requires_perk_name}
                        </Box>
                      )}
                      <Button
                        fluid
                        content="[UNLOCK]"
                        color="good"
                        disabled={!perk.can_unlock}
                        onClick={() => act('unlock', { perk: perk.id })}
                        style={{ marginTop: '8px' }}
                      />
                    </>
                  )}
                </Box>
              </Flex.Item>
            ))}
          </Flex>
        </Section>

        <Box className="CharacterSetup__footer">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>
      </Window.Content>
    </Window>
  );
};
