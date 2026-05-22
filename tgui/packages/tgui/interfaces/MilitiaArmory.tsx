import { useBackend } from '../backend';
import { Button, Section, Table, Stack, NoticeBox, Flex, Box } from '../components';
import { Window } from '../layouts';

type MilitiaArmoryData = {
  is_member?: boolean;
  is_commander?: boolean;
  alert_level?: number;
  mobilized?: boolean;
  max_members?: number;
  rank?: number;
  patrols_completed?: number;
  issued_rifle?: boolean;
  issued_armor?: boolean;
  issued_radio?: boolean;
  members?: MilitiaMember[];
  active_patrols?: Patrol[];
};

type MilitiaMember = {
  ckey?: string;
  name?: string;
  rank?: number;
  patrols?: number;
};

type Patrol = {
  leader?: string;
  type?: string;
};

const alertLevels = [
  { level: 0, name: 'Peaceful' },
  { level: 1, name: 'Elevated' },
  { level: 2, name: 'Danger' },
  { level: 3, name: 'Emergency' },
];

const rankNames: Record<number, string> = {
  1: 'Recruit',
  2: 'Member',
  3: 'Sergeant',
  4: 'Commander',
};

export const MilitiaArmory = (props, context) => {
  const { act, data } = useBackend<MilitiaArmoryData>(context);

  const {
    is_member,
    is_commander,
    alert_level = 0,
    mobilized,
    max_members = 20,
    rank = 1,
    patrols_completed = 0,
    issued_rifle,
    issued_armor,
    issued_radio,
    members = [],
    active_patrols = [],
  } = data;

  return (
    <Window theme="fallout" width={600} height={700}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="Eastwood Militia">
            {!is_member ? (
              <Button onClick={() => act('enlist')}>
                Enlist in Militia
              </Button>
            ) : (
              <Stack vertical>
                <NoticeBox success>
                  You are a {rankNames[rank] || 'Member'} of the Militia.
                </NoticeBox>
                {mobilized && (
                  <NoticeBox danger>MILITIA MOBILIZED!</NoticeBox>
                )}
                <Box>Patrols Completed: {patrols_completed}</Box>
              </Stack>
            )}
          </Section>

          {is_member && (
            <>
              <Section title="Equipment">
                <Flex wrap="wrap" gap="5px">
                  <Button
                    color={issued_rifle ? 'good' : 'bad'}
                    onClick={() => act('issue_equipment', { equipment: 'rifle' })}
                  >
                    Rifle: {issued_rifle ? 'Issued' : 'Not Issued'}
                  </Button>
                  <Button
                    color={issued_armor ? 'good' : 'bad'}
                    onClick={() => act('issue_equipment', { equipment: 'armor' })}
                  >
                    Armor: {issued_armor ? 'Issued' : 'Not Issued'}
                  </Button>
                  <Button
                    color={issued_radio ? 'good' : 'bad'}
                    onClick={() => act('issue_equipment', { equipment: 'radio' })}
                  >
                    Radio: {issued_radio ? 'Issued' : 'Not Issued'}
                  </Button>
                </Flex>
              </Section>

              <Section title="Patrol Duty">
                <Flex gap="5px">
                  <Button onClick={() => act('start_patrol', { patrol_type: 'perimeter' })}>
                    Start Perimeter Patrol
                  </Button>
                  <Button onClick={() => act('start_patrol', { patrol_type: 'town' })}>
                    Start Town Patrol
                  </Button>
                </Flex>
              </Section>
            </>
          )}

          {is_commander && (
            <Section title="Commander Actions">
              <Section title="Alert Level" level>
                <Flex gap="5px">
                  {alertLevels.map(alert => (
                    <Button
                      key={alert.level}
                      color={alert_level === alert.level ? 'good' : 'default'}
                      onClick={() => act('set_alert', { level: alert.level })}
                    >
                      {alert.name}
                    </Button>
                  ))}
                </Flex>
              </Section>
              <Section title="Manage Members" level>
                <Table>
                  <Table.Row header>
                    <Table.Cell>Name</Table.Cell>
                    <Table.Cell>Rank</Table.Cell>
                    <Table.Cell>Patrols</Table.Cell>
                    <Table.Cell>Actions</Table.Cell>
                  </Table.Row>
                  {members.map(member => (
                    <Table.Row key={member.ckey}>
                      <Table.Cell>{member.name}</Table.Cell>
                      <Table.Cell>{rankNames[member.rank || 1]}</Table.Cell>
                      <Table.Cell>{member.patrols}</Table.Cell>
                      <Table.Cell>
                        <Flex gap="2px">
                          <Button onClick={() => act('promote', { target_ckey: member.ckey })}>
                            Promote
                          </Button>
                          <Button onClick={() => act('demote', { target_ckey: member.ckey })}>
                            Demote
                          </Button>
                          <Button onClick={() => act('discharge', { target_ckey: member.ckey })}>
                            Discharge
                          </Button>
                        </Flex>
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            </Section>
          )}

          <Section title={`Active Patrols (${active_patrols.length})`}>
            <Table>
              <Table.Row header>
                <Table.Cell>Leader</Table.Cell>
                <Table.Cell>Type</Table.Cell>
              </Table.Row>
              {active_patrols.map((patrol, index) => (
                <Table.Row key={index}>
                  <Table.Cell>{patrol.leader}</Table.Cell>
                  <Table.Cell>{patrol.type}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>

          <Section title={`Militia Roster (${members.length}/${max_members})`}>
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Rank</Table.Cell>
                <Table.Cell>Patrols</Table.Cell>
              </Table.Row>
              {members.map(member => (
                <Table.Row key={member.ckey}>
                  <Table.Cell>{member.name}</Table.Cell>
                  <Table.Cell>{rankNames[member.rank || 1]}</Table.Cell>
                  <Table.Cell>{member.patrols}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
