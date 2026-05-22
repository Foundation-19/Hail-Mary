import { useBackend } from '../backend';
import { Section, Flex, Button, Box, Divider } from '../components';
import { Window } from '../layouts';

type Data = {
  master_mode: string;
  round_started: boolean;
  dynamic_options: DynamicOptions;
};

type DynamicOptions = {
  forced_rulesets: Array<string>;
  forced_storyteller: string | null;
  has_latejoin_rule: boolean;
};

export const GamePanel = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { master_mode, round_started, dynamic_options } = data;

  return (
    <Window width={400} height={500} title="ROBCO TERMINAL - GAME PANEL" theme="fallout">
      <Window.Content scrollable>
        <Section title="GAME MODE CONTROL">
          <Box mb={2}>
            <Box style={{ marginBottom: '8px', opacity: 0.8 }}>
              CURRENT MODE: <Box as="span" style={{ color: '#6bff6b', fontWeight: 'bold' }}>{master_mode}</Box>
            </Box>
            <Button
              content="> CHANGE GAME MODE"
              fluid
              onClick={() => act('change_mode')}
            />
            {master_mode === 'secret' && (
              <Button
                content="> FORCE SECRET MODE"
                fluid
                mt={1}
                onClick={() => act('force_secret')}
              />
            )}
          </Box>
        </Section>

        {master_mode === 'dynamic' && (
          <Section title="DYNAMIC MODE OPTIONS">
            {!round_started && (
              <>
                <Button
                  content="> FORCE ROUNDSTART RULESETS"
                  fluid
                  onClick={() => act('force_roundstart')}
                />
                {dynamic_options?.forced_rulesets?.map((rule, index) => (
                  <Box key={index} style={{ padding: '4px', opacity: 0.8 }}>
                    {'> '}{rule}
                  </Box>
                ))}
                <Button
                  content="> FORCE STORYTELLER"
                  fluid
                  mt={1}
                  onClick={() => act('force_storyteller')}
                />
                {dynamic_options?.forced_storyteller && (
                  <Box style={{ padding: '4px', opacity: 0.8 }}>
                    {'> '}{dynamic_options.forced_storyteller}
                  </Box>
                )}
              </>
            )}
            {round_started && (
              <>
                <Button
                  content="> FORCE NEXT LATEJOIN RULESET"
                  fluid
                  onClick={() => act('force_latejoin')}
                />
                <Button
                  content="> EXECUTE MIDROUND RULESET"
                  fluid
                  mt={1}
                  color="danger"
                  onClick={() => act('execute_midround')}
                />
              </>
            )}
          </Section>
        )}

        {round_started && master_mode === 'dynamic' && (
          <Section title="ROUND MANAGEMENT">
            <Button
              content="> GAME MODE PANEL"
              fluid
              onClick={() => act('gamemode_panel')}
            />
          </Section>
        )}

        <Section title="ENTITY SPAWNING">
          <Flex direction="column" gap={1}>
            <Button
              content="> CREATE OBJECT"
              fluid
              onClick={() => act('create_object')}
            />
            <Button
              content="> QUICK CREATE OBJECT"
              fluid
              onClick={() => act('quick_create_object')}
            />
            <Button
              content="> CREATE TURF"
              fluid
              onClick={() => act('create_turf')}
            />
            <Button
              content="> CREATE MOB"
              fluid
              onClick={() => act('create_mob')}
            />
          </Flex>
        </Section>
      </Window.Content>
    </Window>
  );
};
