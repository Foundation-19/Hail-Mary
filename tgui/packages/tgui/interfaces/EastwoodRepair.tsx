import { useBackend } from '../backend';
import { Button, Section, Stack, NoticeBox, Flex, Box } from '../components';
import { Window } from '../layouts';

type EastwoodRepairData = {
  basic_cost?: number;
  services?: RepairService[];
  my_jobs?: RepairJob[];
};

type RepairService = {
  id?: string;
  name?: string;
  cost?: number;
  time?: string;
};

type RepairJob = {
  id?: string;
  type?: string;
  cost?: number;
};

export const EastwoodRepair = (props, context) => {
  const { act, data } = useBackend<EastwoodRepairData>(context);

  const {
    basic_cost = 25,
    services = [],
    my_jobs = [],
  } = data;

  return (
    <Window theme="fallout" width={500} height={500}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="Eastwood Repair Shop">
            <NoticeBox info>Submit items for professional repair.</NoticeBox>
          </Section>

          <Section title="Repair Services">
            <Stack vertical>
              {services.map(service => (
                <Flex key={service.id} justify="space-between" align="center" className="candystripe">
                  <Stack vertical>
                    <Box bold>{service.name}</Box>
                    <Box>Est. Time: {service.time}</Box>
                  </Stack>
                  <Flex align="center" gap="10px">
                    <Box>{service.cost} caps</Box>
                    <Button onClick={() => act('submit_repair', { repair_type: service.id })}>
                      Submit Item
                    </Button>
                  </Flex>
                </Flex>
              ))}
            </Stack>
          </Section>

          <Section title="Your Repair Jobs">
            {my_jobs.length === 0 ? (
              <NoticeBox>No active repair jobs.</NoticeBox>
            ) : (
              <Stack vertical>
                {my_jobs.map(job => (
                  <Flex key={job.id} justify="space-between" align="center" className="candystripe">
                    <Box>{job.type} Repair</Box>
                    <Flex align="center" gap="10px">
                      <Box>{job.cost} caps</Box>
                      <Button onClick={() => act('collect_item', { job_id: job.id })}>
                        Collect
                      </Button>
                    </Flex>
                  </Flex>
                ))}
              </Stack>
            )}
          </Section>

          <Section title="Pricing">
            <Box>Basic Repair: {basic_cost} caps</Box>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
