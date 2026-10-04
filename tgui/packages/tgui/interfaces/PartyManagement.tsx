import { useBackend } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Icon,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Tooltip,
} from '../components';
import { Window } from '../layouts';

type PartyMember = {
  ref: string;
  name: string;
  is_leader: boolean;
  is_self: boolean;
};

type PartyAura = {
  type: string;
  name: string;
  desc: string;
  required_tier: number;
  unlocked: boolean;
  is_current: boolean;
};

type Data = {
  is_leader: boolean;
  cap: number;
  aura_name: string;
  members: Array<PartyMember>;
  auras?: Array<PartyAura>;
  rally_ready?: boolean;
  rally_cooldown_seconds?: number;
  rally_tier?: number;
};

export const PartyManagement = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const {
    is_leader,
    cap,
    aura_name,
    members = [],
    auras = [],
    rally_ready,
    rally_cooldown_seconds = 0,
    rally_tier = 0,
  } = data;
  const others = members.filter((member) => !member.is_self);

  return (
    <Window
      width={400}
      height={is_leader ? 620 : 420}
      title="Party Roster"
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section>
              <LabeledList>
                <LabeledList.Item label="Aura">
                  <Icon name="shield-alt" color="good" mr={1} />
                  {aura_name || 'None'}
                </LabeledList.Item>
                <LabeledList.Item label="Members">
                  <Icon name="users" color="label" mr={1} />
                  {members.length} / {cap}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Roster" fill scrollable height="160px">
              {members.length === 0 && (
                <NoticeBox>You aren&apos;t part of a party.</NoticeBox>
              )}
              {members.length > 0 && (
                <Stack vertical>
                  {members.map((member) => (
                    <Stack.Item key={member.ref}>
                      <Box
                        className="PartyManagement__row"
                        p={1}
                        backgroundColor={
                          member.is_self ? 'rgba(255,255,255,0.05)' : undefined
                        }>
                        <Stack align="center">
                          <Stack.Item>
                            <Icon
                              name={member.is_leader ? 'crown' : 'user'}
                              color={member.is_leader ? 'gold' : 'label'}
                              mr={1}
                            />
                          </Stack.Item>
                          <Stack.Item grow>
                            <Box bold={member.is_leader}>
                              {member.name}
                              {member.is_self && ' (You)'}
                            </Box>
                          </Stack.Item>
                          {is_leader && !member.is_self && (
                            <Stack.Item>
                              <Button
                                icon="user-slash"
                                color="bad"
                                tooltip="Kick from party"
                                onClick={() => act('kick', { ref: member.ref })}
                              />
                            </Stack.Item>
                          )}
                        </Stack>
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              )}
              {members.length > 0 && others.length === 0 && (
                <NoticeBox info mt={1}>
                  Nobody else is in your party yet. Invite nearby allies to
                  grow your ranks!
                </NoticeBox>
              )}
            </Section>
          </Stack.Item>
          {is_leader && (
            <Stack.Item grow>
              <Section title="Leadership" fill scrollable>
                <Stack.Item>
                  <Button
                    fluid
                    icon="bullhorn"
                    color={rally_ready ? 'good' : 'disabled'}
                    disabled={!rally_ready || rally_tier <= 0}
                    content={
                      rally_ready
                        ? 'Rally Cry'
                        : `Rally Cry (${rally_cooldown_seconds}s)`
                    }
                    onClick={() => act('rally_cry')}
                  />
                </Stack.Item>
                <Stack.Item mt={1}>
                  <Collapsible title="Choose Aura" open>
                    <Stack vertical>
                      {auras.map((aura) => {
                        const label = aura.unlocked
                          ? aura.name
                          : `${aura.name} (locked, tier ${aura.required_tier})`;
                        return (
                          <Stack.Item key={aura.type}>
                            <Tooltip content={aura.desc}>
                              <Button
                                fluid
                                disabled={!aura.unlocked}
                                selected={aura.is_current}
                                icon={aura.is_current ? 'check' : 'shield-alt'}
                                content={label}
                                onClick={() => act('set_aura', { aura_type: aura.type })}
                              />
                            </Tooltip>
                          </Stack.Item>
                        );
                      })}
                    </Stack>
                  </Collapsible>
                </Stack.Item>
              </Section>
            </Stack.Item>
          )}
          <Stack.Item>
            <Button
              fluid
              icon="door-open"
              color="bad"
              content="Leave Party"
              onClick={() => act('leave')}
            />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
