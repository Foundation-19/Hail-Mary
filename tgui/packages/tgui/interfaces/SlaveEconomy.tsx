import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, Table } from '../components';

type SlaveEconomyData = {
  sites: LaborSite[];
  unassigned_slaves: UnassignedSlave[];
  resource_totals: Record<string, number>;
  total_slaves_working: number;
};

type LaborSite = {
  site_id: string;
  site_name: string;
  site_type: string;
  max_slaves: number;
  current_slaves: number;
  production_rate: number;
  guard_present: boolean;
  resource_storage: Record<string, number>;
  slaves: AssignedSlave[];
};

type AssignedSlave = {
  slave_ckey: string;
  slave_name: string;
  active: boolean;
};

type UnassignedSlave = {
  slave_ckey: string;
  slave_name: string;
  obedience: number;
};

const getSiteTypeColor = (type: string): string => {
  switch (type) {
    case 'mine':
      return 'orange';
    case 'farm':
      return 'green';
    case 'construction':
      return 'blue';
    case 'quarry':
      return 'grey';
    case 'workshop':
      return 'purple';
    default:
      return 'silver';
  }
};

export const SlaveEconomy = (props, context) => {
  const { act, data } = useBackend<SlaveEconomyData>(context);
  const {
    sites = [],
    unassigned_slaves = [],
    resource_totals = {},
    total_slaves_working = 0,
  } = data;

  return (
    <Window
      width={750}
      height={700}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="> LEGION SLAVE ECONOMY">
              <Box color="silver" fontSize="14px">
                LABOR MANAGEMENT SYSTEM
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> ECONOMY OVERVIEW">
              <LabeledList>
                <LabeledList.Item label="Slaves Working">
                  <Box color="green" bold>{total_slaves_working}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Resource Totals">
                  <Stack>
                    {Object.entries(resource_totals)
                      .map(([resource, amount]) => (
                        <Stack.Item key={resource} mr={2}>
                          <Box color="gold">{resource}: {amount}</Box>
                        </Stack.Item>
                      ))}
                  </Stack>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> LABOR SITES">
              {sites.map(site => (
                <Box key={site.site_id} mb={2} p={1} backgroundColor="rgba(50,50,50,0.5)">
                  <Stack>
                    <Stack.Item grow>
                      <LabeledList>
                        <LabeledList.Item label="Site">
                          <Box color={getSiteTypeColor(site.site_type)} bold>
                            {site.site_name}
                          </Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Type">
                          <Box color="silver">{site.site_type.toUpperCase()}</Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Workers">
                          <Box color={site.current_slaves > 0 ? 'green' : 'grey'}>
                            {site.current_slaves}/{site.max_slaves}
                          </Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Guarded">
                          <Box color={site.guard_present ? 'green' : 'red'}>
                            {site.guard_present ? 'Yes' : 'No'}
                          </Box>
                        </LabeledList.Item>
                      </LabeledList>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        color="good"
                        size="tiny"
                        onClick={() => act('collect_resources', {
                          site_id: site.site_id,
                        })}>
                        Collect
                      </Button>
                    </Stack.Item>
                  </Stack>
                  {site.slaves && site.slaves.length > 0 && (
                    <Box mt={1}>
                      <Box color="silver" fontSize="12px">Assigned:</Box>
                      {site.slaves.map(slave => (
                        <Box key={slave.slave_ckey} fontSize="12px" ml={1}>
                          {slave.slave_name}
                          <Button
                            color="red"
                            size="tiny"
                            ml={1}
                            onClick={() => act('remove_slave', {
                              slave_ckey: slave.slave_ckey,
                              site_id: site.site_id,
                            })}>
                            Remove
                          </Button>
                        </Box>
                      ))}
                    </Box>
                  )}
                </Box>
              ))}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> UNASSIGNED SLAVES">
              {!unassigned_slaves.length && (
                <Box color="grey" textAlign="center" py={2}>
                  No unassigned labor slaves available.
                </Box>
              )}
              {unassigned_slaves.map(slave => (
                <Box key={slave.slave_ckey} mb={1} p={1} backgroundColor="rgba(50,50,50,0.3)">
                  <Stack>
                    <Stack.Item grow>
                      <Box color="silver">{slave.slave_name}</Box>
                      <Box color="grey" fontSize="12px">
                        Obedience: {slave.obedience}%
                      </Box>
                    </Stack.Item>
                    <Stack.Item>
                      {sites.map(site => (
                        <Button
                          key={site.site_id}
                          color="steel"
                          size="tiny"
                          mr={1}
                          disabled={site.current_slaves >= site.max_slaves}
                          onClick={() => act('assign_slave', {
                            slave_ckey: slave.slave_ckey,
                            site_id: site.site_id,
                          })}>
                          {site.site_name}
                        </Button>
                      ))}
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
