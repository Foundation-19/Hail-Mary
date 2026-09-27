import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { Button, LabeledList, NoticeBox, Section } from '../components';
import { Window } from '../layouts';

export const PortableTurret = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    silicon_user,
    locked,
    on,
    turret_shoot_weapons,
    turret_shoot_wildlife,
    turret_shoot_all,
    turret_shoot_players,
    turret_shoot_raiders,
    turret_shoot_robots,
    turret_shoot_ignore_faction,
    turret_make_noise,
    turret_use_laser_pointer,
    manual_control,
    allow_manual_control,
    lasertag_turret,
    generator_linked,
    generator_name,
    generator_powered,
  } = data;
  return (
    <Window
      theme="fallout"
      width={310}
      height={lasertag_turret ? 110 : 420}>
      <Window.Content>
        <NoticeBox>
          {locked ? 'Unlock' : 'Lock'} this interface with an ID card.
          <Button
            ml={1}
            icon={locked ? 'unlock' : 'lock'}
            content={locked ? 'Unlock' : 'Lock'}
            onClick={() => act('unlock')} />
        </NoticeBox>
        {!lasertag_turret && (
          <NoticeBox
            danger={!generator_linked}
            success={generator_linked && generator_powered}>
            {!generator_linked
              && 'Not linked to a generator -- multitool a generator, '
              + 'then multitool this turret.'}
            {generator_linked && generator_powered
              && `Linked to ${generator_name} -- running.`}
            {generator_linked && !generator_powered
              && `Linked to ${generator_name} -- offline.`}
          </NoticeBox>
        )}
        <Fragment>
          <Section>
            <LabeledList>
              <LabeledList.Item
                label="Status"
                buttons={!lasertag_turret && (!!allow_manual_control
                  || (!!manual_control && !!silicon_user)) && (
                  <Button
                    icon={manual_control ? "wifi" : "terminal"}
                    content={manual_control
                      ? "Remotely Controlled"
                      : "Manual Control"}
                    disabled={manual_control}
                    color="bad"
                    onClick={() => act('manual')} />
                )}>
                <Button
                  icon={on ? 'power-off' : 'times'}
                  content={on ? 'On' : 'Off'}
                  selected={on}
                  disabled={locked}
                  onClick={() => act('power')} />
              </LabeledList.Item>
            </LabeledList>
          </Section>
          {!lasertag_turret && (
            <Section
              title="Target Settings"
              buttons={(
                <Button.Checkbox
                  checked={!turret_shoot_ignore_faction}
                  content="Disable IFF"
                  disabled={locked}
                  onClick={() => act('turret_return_ignore_faction')} />
              )}>
              <Button.Checkbox
                fluid
                checked={turret_shoot_players}
                content="Target Wastelanders"
                disabled={locked}
                onClick={() => act('turret_return_shoot_players')} />
              <Button.Checkbox
                fluid
                checked={turret_shoot_raiders}
                content="Target Raiders"
                disabled={locked}
                onClick={() => act('turret_return_shoot_raiders')} />
              <Button.Checkbox
                fluid
                checked={turret_shoot_wildlife}
                content="Target Wildlife"
                disabled={locked}
                onClick={() => act('turret_return_shoot_wildlife')} />
              <Button.Checkbox
                fluid
                checked={turret_shoot_robots}
                content="Target Robots"
                disabled={locked}
                onClick={() => act('turret_return_shoot_robots')} />
              <Button.Checkbox
                fluid
                checked={turret_use_laser_pointer}
                content="Use Targeting Laser"
                disabled={locked}
                onClick={() => act('turret_return_use_laser_pointer')} />
              <Button.Checkbox
                fluid
                checked={turret_make_noise}
                content="Use Internal Speakers"
                disabled={locked}
                onClick={() => act('turret_return_make_noise')} />
            </Section>
          )}
        </Fragment>
      </Window.Content>
    </Window>
  );
};
