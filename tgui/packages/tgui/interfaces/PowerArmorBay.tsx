import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, ProgressBar } from '../components';

type PowerArmorBayData = {
  mastery: PAMastery;
  bos_reputation: number;
  is_wearing_pa: boolean;
  active_suit: PASuit;
  available_mods: PAMod[];
};

type PAMastery = {
  skill_level: number;
  skill_name: string;
  training_hours: number;
  training_in_progress: boolean;
  suits_mastered: string[];
  movement_bonus: number;
  fuel_efficiency: number;
  next_level_hours: number;
};

type PASuit = {
  has_suit: boolean;
  name: string;
  condition: number;
  fuel: number;
  mods: string[];
};

type PAMod = {
  id: string;
  name: string;
  description: string;
  skill_required: number;
  can_install: boolean;
  rarity: string;
  installation_time: number;
};

const getRarityColor = (rarity: string): string => {
  switch (rarity) {
    case 'common':
      return 'grey';
    case 'uncommon':
      return 'green';
    case 'rare':
      return 'blue';
    case 'legendary':
      return 'gold';
    default:
      return 'grey';
  }
};

export const PowerArmorBay = (props, context) => {
  const { act, data } = useBackend<PowerArmorBayData>(context);
  const {
    mastery,
    is_wearing_pa,
    active_suit,
    available_mods = [],
  } = data;

  return (
    <Window
      width={650}
      height={700}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="> BROTHERHOOD OF STEEL">
              <Box color="silver" fontSize="14px">
                POWER ARMOR BAY
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> YOUR TRAINING">
              <LabeledList>
                <LabeledList.Item label="Level">
                  <Box color="gold" bold>
                    {mastery?.skill_name || 'Untrained'} ({mastery?.skill_level || 0})
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Training Hours">
                  <Box color="silver">
                    {mastery?.training_hours?.toFixed(1) || 0}
                    {mastery?.next_level_hours > 0
                      && ` / ${mastery.next_level_hours} for next level`}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Movement Bonus">
                  <Box color="green">+{mastery?.movement_bonus || 0}%</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Fuel Efficiency">
                  <Box color="blue">{((mastery?.fuel_efficiency || 1) * 100).toFixed(0)}%</Box>
                </LabeledList.Item>
              </LabeledList>
              <Box mt={2}>
                <Button
                  color={mastery?.training_in_progress ? 'grey' : 'good'}
                  disabled={mastery?.training_in_progress}
                  onClick={() => act('start_training')}>
                  {mastery?.training_in_progress ? 'Training in Progress...' : 'Start Training Simulation'}
                </Button>
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> ACTIVE SUIT">
              {active_suit?.has_suit ? (
                <Stack vertical>
                  <Stack.Item>
                    <LabeledList>
                      <LabeledList.Item label="Suit">
                        <Box color="steel" bold>{active_suit.name}</Box>
                      </LabeledList.Item>
                      <LabeledList.Item label="Condition">
                        <ProgressBar
                          value={active_suit.condition}
                          minValue={0}
                          maxValue={100}
                          color={active_suit.condition > 50 ? 'good' : 'bad'}>
                          {active_suit.condition}%
                        </ProgressBar>
                      </LabeledList.Item>
                      <LabeledList.Item label="Fuel">
                        <ProgressBar
                          value={active_suit.fuel}
                          minValue={0}
                          maxValue={100}
                          color="blue">
                          {active_suit.fuel}%
                        </ProgressBar>
                      </LabeledList.Item>
                    </LabeledList>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      color="good"
                      disabled={
                        !is_wearing_pa || (mastery?.skill_level || 0) < 1
                      }
                      onClick={() => act('perform_maintenance')}>
                      Perform Maintenance
                    </Button>
                  </Stack.Item>
                </Stack>
              ) : (
                <Box color="grey" textAlign="center" py={2}>
                  No power armor equipped.
                </Box>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> AVAILABLE MODS">
              {!available_mods.length && (
                <Box color="grey" textAlign="center" py={2}>
                  No mods available.
                </Box>
              )}
              {available_mods.map(mod => (
                <Box key={mod.id} mb={2} p={1} backgroundColor="rgba(50,50,50,0.5)">
                  <LabeledList>
                    <LabeledList.Item label="Name">
                      <Box color={getRarityColor(mod.rarity)} bold>
                        {mod.name}
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Description">
                      <Box color="grey" fontSize="12px">{mod.description}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Skill Required">
                      <Box color={mod.can_install ? 'green' : 'red'}>
                        Level {mod.skill_required}
                        {!mod.can_install && ' (Insufficient)'}
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Install Time">
                      <Box color="silver">{mod.installation_time} minutes</Box>
                    </LabeledList.Item>
                  </LabeledList>
                  <Box mt={1}>
                    <Button
                      color={mod.can_install && is_wearing_pa ? 'good' : 'grey'}
                      disabled={!mod.can_install || !is_wearing_pa}
                      onClick={() => act('install_mod', { mod_id: mod.id })}>
                      {is_wearing_pa ? 'Install' : 'No Suit Equipped'}
                    </Button>
                  </Box>
                </Box>
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
