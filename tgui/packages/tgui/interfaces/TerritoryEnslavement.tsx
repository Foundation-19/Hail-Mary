import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, ProgressBar } from '../components';

type TerritoryEnslavementData = {
  territories: EnslavedTerritory[];
  total_enslaved: number;
  total_revenue: number;
};

type EnslavedTerritory = {
  territory_id: string;
  territory_name: string;
  owner_faction: string;
  population: number;
  enslaved_percent: number;
  enslaved_count: number;
  resistance_level: number;
  generation_rate: number;
  legion_presence: number;
};

const getResistanceColor = (level: number): string => {
  if (level < 20) return 'green';
  if (level < 50) return 'yellow';
  if (level < 80) return 'orange';
  return 'red';
};

export const TerritoryEnslavement = (props, context) => {
  const { act, data } = useBackend<TerritoryEnslavementData>(context);
  const {
    territories = [],
    total_enslaved = 0,
    total_revenue = 0,
  } = data;

  return (
    <Window
      width={700}
      height={650}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="> LEGION TERRITORY MANAGEMENT">
              <Box color="silver" fontSize="14px">
                POPULATION CONTROL SYSTEM
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> OVERVIEW">
              <LabeledList>
                <LabeledList.Item label="Total Enslaved">
                  <Box color="red" bold>{total_enslaved}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Total Revenue">
                  <Box color="gold">{total_revenue.toFixed(0)} caps/tick</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Territories">
                  <Box color="silver">{territories.length}</Box>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> ENSLAVED TERRITORIES">
              {territories.map(territory => (
                <Box
                  key={territory.territory_id}
                  mb={2}
                  p={1}
                  backgroundColor="rgba(50,50,50,0.5)">
                  <LabeledList>
                    <LabeledList.Item label="Territory">
                      <Box
                        color={
                          territory.owner_faction === 'legion'
                            ? 'red'
                            : 'grey'
                        }
                        bold>
                        {territory.territory_name}
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Population">
                      <Box color="silver">{territory.population}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Enslaved">
                      <Stack>
                        <Stack.Item>
                          <Box color="red">
                            {territory.enslaved_count}
                            ({territory.enslaved_percent}%)
                          </Box>
                        </Stack.Item>
                        <Stack.Item grow>
                          <ProgressBar
                            value={territory.enslaved_percent}
                            minValue={0}
                            maxValue={50}
                            color="red">
                            {territory.enslaved_percent}%
                          </ProgressBar>
                        </Stack.Item>
                      </Stack>
                    </LabeledList.Item>
                    <LabeledList.Item label="Resistance">
                      <ProgressBar
                        value={territory.resistance_level}
                        minValue={0}
                        maxValue={100}
                        color={getResistanceColor(territory.resistance_level)}>
                        {territory.resistance_level}%
                      </ProgressBar>
                    </LabeledList.Item>
                    <LabeledList.Item label="Legion Presence">
                      <Box color="green">{territory.legion_presence}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Revenue">
                      <Box color="gold">
                        {(territory.population
                          * (territory.enslaved_percent / 100)
                          * territory.generation_rate).toFixed(0)} caps/tick
                      </Box>
                    </LabeledList.Item>
                  </LabeledList>
                  <Stack mt={1}>
                    <Stack.Item>
                      <Button
                        color="red"
                        size="tiny"
                        disabled={
                          territory.owner_faction !== 'legion'
                          || territory.enslaved_percent >= 50
                        }
                        onClick={() => act('enslave_more', {
                          territory_id: territory.territory_id,
                          percent: 5,
                        })}>
                        Enslave More
                      </Button>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        color="green"
                        size="tiny"
                        disabled={territory.enslaved_percent <= 0}
                        onClick={() => act('free_slaves', {
                          territory_id: territory.territory_id,
                          percent: 10,
                        })}>
                        Free Slaves
                      </Button>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        color="orange"
                        size="tiny"
                        disabled={
                          territory.owner_faction !== 'legion'
                          || territory.resistance_level <= 0
                        }
                        onClick={() => act('crack_down', {
                          territory_id: territory.territory_id,
                        })}>
                        Crack Down
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Box>
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
