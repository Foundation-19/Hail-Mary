import { useBackend } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';

export const PowerAttackSelect = (props, context) => {
  const { act, data } = useBackend(context);
  const { item_name, active_path, power_attacks = [] } = data;
  return (
    <Window theme="fallout" width={420} height={430}>
      <Window.Content scrollable>
        <Section title={item_name + ' \u2014 Power Attacks'}>
          <Box color="label" mb={1}>
            Hold left click while wielding this weapon to charge the armed
            Power Attack below, then release on a target to unleash it.
          </Box>
          <Stack vertical>
            {power_attacks.map(power_attack => (
              <Stack.Item key={power_attack.path}>
                <Section
                  title={power_attack.name}
                  buttons={(
                    <Button
                      icon={power_attack.path === active_path ? 'check' : 'crosshairs'}
                      content={power_attack.path === active_path ? 'Armed' : 'Select'}
                      disabled={!power_attack.selectable}
                      selected={power_attack.path === active_path}
                      onClick={() => act('select', { path: power_attack.path })} />
                  )}>
                  <Box>{power_attack.desc}</Box>
                  <Box color="label" mt={0.5}>
                    {'Windup: ' + power_attack.windup_time + 's \u00b7 Stamina: '
                      + power_attack.stamina_cost + ' \u00b7 Damage: x' + power_attack.damage_multiplier}
                    {!power_attack.selectable && ' \u00b7 Unavailable with this weapon'}
                  </Box>
                </Section>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
