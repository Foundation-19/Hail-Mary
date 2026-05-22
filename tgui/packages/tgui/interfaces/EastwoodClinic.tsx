import { useBackend } from '../backend';
import { Button, Section, Stack, NoticeBox, Flex, Box } from '../components';
import { Window } from '../layouts';

type EastwoodClinicData = {
  basic_heal_cost?: number;
  surgery_cost?: number;
  treatments?: Treatment[];
};

type Treatment = {
  id?: string;
  name?: string;
  cost?: number;
  desc?: string;
};

export const EastwoodClinic = (props, context) => {
  const { act, data } = useBackend<EastwoodClinicData>(context);

  const {
    basic_heal_cost = 50,
    surgery_cost = 200,
    treatments = [],
  } = data;

  return (
    <Window theme="fallout" width={500} height={500}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="Eastwood Clinic">
            <NoticeBox info>Medical services available 24/7.</NoticeBox>
          </Section>

          <Section title="Available Treatments">
            <Stack vertical>
              {treatments.map(treatment => (
                <Flex key={treatment.id} justify="space-between" align="center" className="candystripe">
                  <Stack vertical>
                    <Box bold>{treatment.name}</Box>
                    <Box>{treatment.desc}</Box>
                  </Stack>
                  <Flex align="center" gap="10px">
                    <Box>{treatment.cost} caps</Box>
                    <Button onClick={() => act('request_treatment', { treatment: treatment.id })}>
                      Request
                    </Button>
                  </Flex>
                </Flex>
              ))}
            </Stack>
          </Section>

          <Section title="Pricing">
            <Flex direction="column" gap="5px">
              <Box>Basic Treatment: {basic_heal_cost} caps</Box>
              <Box>Surgery: {surgery_cost} caps</Box>
            </Flex>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
