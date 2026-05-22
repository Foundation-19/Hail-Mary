import { useBackend } from '../backend';
import { Button, Section, Table, Stack, NoticeBox, Flex, Box } from '../components';
import { Window } from '../layouts';

type NCRLiaisonData = {
  protectorate_active?: boolean;
  weekly_tribute?: number;
  tribute_due?: boolean;
  protection_level?: number;
  trade_agreement?: boolean;
  garrison_count?: number;
  garrison_max?: number;
  garrison?: GarrisonTroop[];
  benefits?: ProtectionBenefits;
};

type GarrisonTroop = {
  ckey?: string;
  name?: string;
  rank?: string;
};

type ProtectionBenefits = {
  patrols?: string;
  trade_bonus?: number;
  garrison_limit?: number;
};

export const NCRLiaison = (props, context) => {
  const { act, data } = useBackend<NCRLiaisonData>(context);

  const {
    protectorate_active,
    weekly_tribute = 500,
    tribute_due,
    protection_level = 2,
    trade_agreement,
    garrison_count = 0,
    garrison_max = 10,
    garrison = [],
    benefits,
  } = data;

  return (
    <Window theme="fallout" width={600} height={600}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="NCR-Eastwood Protectorate">
            {protectorate_active ? (
              <NoticeBox success>Protectorate Active</NoticeBox>
            ) : (
              <NoticeBox danger>Protectorate Inactive</NoticeBox>
            )}
          </Section>

          <Section title="Tribute">
            <Flex justify="space-between" align="center">
              <Box>Weekly Tribute: <b>{weekly_tribute} caps</b></Box>
              {tribute_due ? (
                <NoticeBox warning>Tribute Due!</NoticeBox>
              ) : (
                <NoticeBox success>Tribute Paid</NoticeBox>
              )}
            </Flex>
            <Button onClick={() => act('pay_tribute')}>
              Pay Tribute
            </Button>
          </Section>

          <Section title={`Protection Level: ${protection_level}`}>
            <Flex gap="5px" wrap="wrap">
              {[1, 2, 3, 4, 5].map(level => (
                <Button
                  key={level}
                  color={protection_level === level ? 'good' : 'default'}
                  onClick={() => act('set_protection', { level: level })}
                >
                  Level {level}
                </Button>
              ))}
            </Flex>
            {benefits && (
              <Stack vertical mt={1}>
                <Box>Patrols: {benefits.patrols}</Box>
                <Box>
                  Trade Bonus: {((benefits.trade_bonus || 0) * 100).toFixed(0)}%
                </Box>
                <Box>Garrison Limit: {benefits.garrison_limit}</Box>
              </Stack>
            )}
          </Section>

          <Section title="Trade Agreement">
            <Flex justify="space-between" align="center">
              <Box>Status: {trade_agreement ? 'Active' : 'Suspended'}</Box>
              <Button onClick={() => act('toggle_trade')}>
                {trade_agreement ? 'Suspend' : 'Activate'} Trade
              </Button>
            </Flex>
          </Section>

          <Section title={`NCR Garrison (${garrison_count}/${garrison_max})`}>
            <Button onClick={() => act('add_garrison')}>
              Join Garrison
            </Button>
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Rank</Table.Cell>
                <Table.Cell>Actions</Table.Cell>
              </Table.Row>
              {garrison.map(troop => (
                <Table.Row key={troop.ckey}>
                  <Table.Cell>{troop.name}</Table.Cell>
                  <Table.Cell>{troop.rank}</Table.Cell>
                  <Table.Cell>
                    <Button onClick={() => act('remove_garrison', { target_ckey: troop.ckey })}>
                      Remove
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
