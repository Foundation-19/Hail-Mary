import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
} from '../components';
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
    faction_locked,
    whitelist_active,
    id_whitelist = [],
    can_manage_owners,
    pending_add_owner,
  } = data;
  return (
    <Window
      theme="fallout"
      width={310}
      height={lasertag_turret ? 110 : 460}>
      <Window.Content scrollable>
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
          <Section title="Status">
            <LabeledList>
              <LabeledList.Item
                label="Power"
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
          {!lasertag_turret && (
            <Section title="Ownership">
              {!!faction_locked && (
                <NoticeBox>
                  Ownership is locked down and cannot be reassigned.
                </NoticeBox>
              )}
              {!faction_locked && (
                <Fragment>
                  {whitelist_active && id_whitelist.length > 0 ? (
                    <LabeledList>
                      {id_whitelist.map((ownerName) => (
                        <LabeledList.Item key={ownerName} label={ownerName}>
                          <Button
                            icon="user-slash"
                            content="Remove"
                            color="danger"
                            disabled={locked || !can_manage_owners}
                            onClick={() => act('remove_owner', {
                              name: ownerName,
                            })} />
                        </LabeledList.Item>
                      ))}
                    </LabeledList>
                  ) : (
                    <Box color="label" mb={1}>
                      No registered owners -- this turret will target
                      anyone its settings allow.
                    </Box>
                  )}
                  <Box color="label">
                    Scan an ID card directly on the turret to add or
                    remove an owner (protected from targeting).
                  </Box>
                  {can_manage_owners && (
                    pending_add_owner ? (
                      <NoticeBox>
                        Awaiting ID card scan to authorize a new owner...
                        <Button
                          ml={1}
                          icon="times"
                          content="Cancel"
                          disabled={locked}
                          onClick={() => act('cancel_add_owner')} />
                      </NoticeBox>
                    ) : (
                      <Button
                        fluid
                        icon="user-plus"
                        content="Add Authorized Owner"
                        disabled={locked}
                        onClick={() => act('start_add_owner')} />
                    )
                  )}
                </Fragment>
              )}
            </Section>
          )}
        </Fragment>
      </Window.Content>
    </Window>
  );
};
