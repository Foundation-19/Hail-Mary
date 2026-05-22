import { useBackend, useLocalState } from '../backend';
import {
  Button,
  Section,
  Stack,
  Flex,
  Box,
  Table,
  NoticeBox,
  ProgressBar,
  LabeledList,
  Tabs,
} from '../components';
import { Window } from '../layouts';

type FEVResearchData = {
  research_points?: number;
  projects?: Project[];
  test_subjects?: TestSubject[];
  can_create_weapons?: boolean;
  synthesis_materials?: Record<string, number>;
  fev_vat_level?: number;
  max_fev_vat?: number;
  available_strains?: Strain[];
  custom_strain_count?: number;
  max_custom_strains?: number;
};

type Project = {
  id?: string;
  name?: string;
  cost?: number;
  progress?: number;
  effect?: string;
  unlocked?: boolean;
  category?: string;
  tests_successful?: number;
  discovered_effects?: string;
};

type TestSubject = {
  ckey?: string;
  name?: string;
};

type Strain = {
  id?: string;
  name?: string;
  desc?: string;
  stability?: number;
  success_mod?: number;
  magnitude_mod?: number;
  fev_cost?: number;
  materials?: Record<string, number>;
};

const categoryColors: Record<string, string> = {
  physical: '#ff6644',
  sensory: '#44aaff',
  mental: '#aa44ff',
  resistance: '#44ffaa',
  healing: '#ffaa44',
  transformation: '#ff44aa',
};

const categoryLabels: Record<string, string> = {
  physical: 'Physical',
  sensory: 'Sensory',
  mental: 'Mental',
  resistance: 'Resistance',
  healing: 'Healing',
  transformation: 'Transformation',
};

const materialLabels: Record<string, string> = {
  biological_matter: 'Biological Matter',
  genetic_data: 'Genetic Data',
  radiation_sample: 'Radiation Sample',
  refined_fev: 'Refined FEV',
};

export const FEVResearch = (props, context) => {
  const { act, data } = useBackend<FEVResearchData>(context);
  const {
    research_points = 0,
    projects = [],
    test_subjects = [],
    can_create_weapons,
    synthesis_materials = {},
    fev_vat_level = 0,
    max_fev_vat = 100,
    available_strains = [],
    custom_strain_count = 0,
    max_custom_strains = 5,
  } = data;
  const [tab, setTab] = useLocalState(context, 'fev-tab', 1);
  const projectsByCategory = projects.reduce(
    (acc, project) => {
      const cat = project.category || 'physical';
      if (!acc[cat]) {
        acc[cat] = [];
      }
      acc[cat].push(project);
      return acc;
    },
    {} as Record<string, Project[]>
  );

  return (
    <Window theme="fallout" width={800} height={800}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="> ENCLAVE FEV RESEARCH">
            <Flex justify="space-between" align="center" wrap>
              <Flex.Item>
                <Box color="silver">
                  GENETIC MODIFICATION DIVISION
                </Box>
              </Flex.Item>
              <Flex.Item>
                <Box>
                  Research Points:{' '}
                  <Box as="span" color="#4cff4c">
                    {research_points}
                  </Box>
                </Box>
              </Flex.Item>
              <Flex.Item>
                <Box>
                  FEV Vat:{' '}
                  <Box
                    as="span"
                    color={
                      fev_vat_level > 50 ? '#4cff4c' : '#ffcc00'
                    }
                  >
                    {fev_vat_level}/{max_fev_vat}
                  </Box>
                </Box>
              </Flex.Item>
            </Flex>
          </Section>

          <Tabs>
            <Tabs.Tab selected={tab === 1} onClick={() => setTab(1)}>
              Research Projects
            </Tabs.Tab>
            <Tabs.Tab selected={tab === 2} onClick={() => setTab(2)}>
              Strain Synthesis
            </Tabs.Tab>
            <Tabs.Tab selected={tab === 3} onClick={() => setTab(3)}>
              Test Subjects
            </Tabs.Tab>
          </Tabs>

          {tab === 1 && (
            <>
              <NoticeBox warning>
                PROJECT EFFECTS ARE CLASSIFIED. Testing
                required to discover outcomes. Risk levels
                are estimates only.
              </NoticeBox>
              {Object.entries(projectsByCategory).map(
                ([category, catProjects]) => (
                  <Section
                    key={category}
                    title={`> ${
                      categoryLabels[category] || category
                    } PROJECTS`}
                  >
                    <Stack vertical>
                      {catProjects.map((project) => (
                        <Box
                          key={project.id}
                          p={1}
                          backgroundColor="rgba(30,50,30,0.5)"
                          style={{
                            borderLeft: `3px solid ${
                              categoryColors[category] || '#888'
                            }`,
                          }}
                        >
                          <Flex
                            justify="space-between"
                            align="flex-start"
                          >
                            <Flex.Item grow={1}>
                              <Flex align="center" gap={1}>
                                <Box
                                  color={
                                    project.unlocked
                                      ? '#4cff4c'
                                      : '#d0d0d0'
                                  }
                                  bold
                                >
                                  {project.name}
                                </Box>
                                {project.unlocked
                                  && project.tests_successful > 0 && (
                                  <Box
                                    color="#888"
                                    fontSize="11px"
                                  >
                                    [Tests: {project.tests_successful}]
                                  </Box>
                                )}
                              </Flex>
                              <Box color="grey" fontSize="12px">
                                {project.discovered_effects}
                              </Box>
                              <Box fontSize="12px">
                                Cost: {project.cost} RP
                              </Box>
                            </Flex.Item>
                            <Flex.Item>
                              {!project.unlocked && (
                                <Button
                                  disabled={
                                    (research_points || 0)
                                    < (project.cost || 0)
                                  }
                                  onClick={() =>
                                    act('unlock_project', {
                                      project_id: project.id,
                                    })}
                                >
                                  Unlock
                                </Button>
                              )}
                              {project.unlocked && (
                                <Flex gap={1}>
                                  <Button
                                    color="bad"
                                    onClick={() =>
                                      act('test_project', {
                                        project_id: project.id,
                                      })}
                                  >
                                    Test on Self
                                  </Button>
                                  {project.discovered_effects
                                    !== 'Not yet tested' && (
                                    <Button
                                      onClick={() =>
                                        act('extract_genetic_data', {
                                          project_id: project.id,
                                        })}
                                    >
                                      Extract Data
                                    </Button>
                                  )}
                                </Flex>
                              )}
                            </Flex.Item>
                          </Flex>
                        </Box>
                      ))}
                    </Stack>
                  </Section>
                )
              )}
            </>
          )}

          {tab === 2 && (
            <>
              <Section title="> SYNTHESIS MATERIALS">
                <LabeledList>
                  {Object.entries(synthesis_materials).map(
                    ([material, amount]) => (
                      <LabeledList.Item
                        key={material}
                        label={
                          materialLabels[material] || material
                        }
                      >
                        <Box
                          color={amount > 0 ? '#4cff4c' : '#888'}
                        >
                          {amount}
                        </Box>
                      </LabeledList.Item>
                    )
                  )}
                </LabeledList>
                <Box mt={1}>
                  <ProgressBar
                    value={fev_vat_level}
                    maxValue={max_fev_vat}
                    color={
                      fev_vat_level > 50 ? 'good' : 'average'
                    }
                  >
                    FEV Vat: {fev_vat_level}/{max_fev_vat}
                  </ProgressBar>
                </Box>
              </Section>

              <Section title="> AVAILABLE STRAINS">
                <NoticeBox info>
                  Each strain has different effect biases and
                  success modifiers. Higher stability = more
                  predictable results.
                </NoticeBox>
                <Table>
                  <Table.Row header>
                    <Table.Cell>Strain</Table.Cell>
                    <Table.Cell>Stability</Table.Cell>
                    <Table.Cell>Success</Table.Cell>
                    <Table.Cell>Magnitude</Table.Cell>
                    <Table.Cell>FEV Cost</Table.Cell>
                    <Table.Cell>Materials</Table.Cell>
                    <Table.Cell>Action</Table.Cell>
                  </Table.Row>
                  {available_strains.map((strain) => {
                    const canSynth
                      = fev_vat_level >= (strain.fev_cost || 0)
                      && Object.entries(strain.materials || {}).every(
                        ([mat, cost]) =>
                          (synthesis_materials[mat] || 0) >= (cost || 0)
                      );
                    return (
                      <Table.Row key={strain.id}>
                        <Table.Cell>
                          <Box bold>{strain.name}</Box>
                          <Box color="grey" fontSize="11px">
                            {strain.desc}
                          </Box>
                        </Table.Cell>
                        <Table.Cell>
                          <Box
                            color={
                              (strain.stability || 0) > 70
                                ? 'good'
                                : (strain.stability || 0) > 50
                                  ? 'average'
                                  : 'bad'
                            }
                          >
                            {strain.stability}%
                          </Box>
                        </Table.Cell>
                        <Table.Cell>
                          <Box
                            color={
                              (strain.success_mod || 0) >= 0
                                ? 'good'
                                : 'bad'
                            }
                          >
                            {(strain.success_mod || 0) >= 0
                              ? '+'
                              : ''}
                            {strain.success_mod}%
                          </Box>
                        </Table.Cell>
                        <Table.Cell>
                          <Box
                            color={
                              (strain.magnitude_mod || 0) >= 0
                                ? 'good'
                                : 'bad'
                            }
                          >
                            {(strain.magnitude_mod || 0) >= 0
                              ? '+'
                              : ''}
                            {strain.magnitude_mod}
                          </Box>
                        </Table.Cell>
                        <Table.Cell>
                          {strain.fev_cost}
                        </Table.Cell>
                        <Table.Cell>
                          {Object.entries(
                            strain.materials || {}
                          ).map(([mat, cost]) => (
                            <Box key={mat} fontSize="11px">
                              {materialLabels[mat] || mat}:{' '}
                              {cost}
                            </Box>
                          ))}
                        </Table.Cell>
                        <Table.Cell>
                          <Button
                            disabled={!canSynth}
                            color={
                              canSynth ? 'good' : undefined
                            }
                            onClick={() =>
                              act('synthesize_strain', {
                                strain_type: strain.id,
                              })}
                          >
                            Synthesize
                          </Button>
                        </Table.Cell>
                      </Table.Row>
                    );
                  })}
                </Table>
              </Section>

              <Section title="> CUSTOM STRAIN CREATOR">
                <NoticeBox>
                  Custom strains let you prioritize specific
                  effect categories. Created:{' '}
                  {custom_strain_count}/{max_custom_strains}.
                </NoticeBox>
                <Flex gap={1} wrap>
                  {[
                    'physical',
                    'sensory',
                    'mental',
                    'resistance',
                    'healing',
                  ].map((cat) => (
                    <Flex.Item key={cat}>
                      <Box
                        color={categoryColors[cat]}
                        fontSize="12px"
                      >
                        {categoryLabels[cat]} Priority
                      </Box>
                      <Button
                        onClick={() =>
                          act('set_priority', { cat, val: 1 })}>
                        Low
                      </Button>
                      <Button
                        onClick={() =>
                          act('set_priority', { cat, val: 2 })}>
                        Med
                      </Button>
                      <Button
                        onClick={() =>
                          act('set_priority', { cat, val: 4 })}>
                        High
                      </Button>
                    </Flex.Item>
                  ))}
                </Flex>
                <Box mt={1}>
                  <Button
                    disabled={
                      custom_strain_count >= max_custom_strains
                    }
                    onClick={() =>
                      act('create_custom_strain', {
                        name: 'Custom',
                      })}
                  >
                    Create Custom Strain
                  </Button>
                </Box>
              </Section>
            </>
          )}

          {tab === 3 && (
            <>
              <Section title="> TEST SUBJECTS">
                {test_subjects.length === 0 ? (
                  <Box color="grey">
                    No test subjects available. Drag a
                    restrained human to the terminal.
                  </Box>
                ) : (
                  <>
                    <NoticeBox warning>
                      Test subjects are consumed in research.
                      Karma penalty: -30
                    </NoticeBox>
                    <Table>
                      <Table.Row header>
                        <Table.Cell>Name</Table.Cell>
                        <Table.Cell>Actions</Table.Cell>
                      </Table.Row>
                      {test_subjects.map((subject, idx) => (
                        <Table.Row key={idx}>
                          <Table.Cell>
                            {subject.name}
                          </Table.Cell>
                          <Table.Cell>
                            <Button
                              color="bad"
                              onClick={() =>
                                act('consume_subject', {
                                  ckey: subject.ckey,
                                })}
                            >
                              Use for Research
                            </Button>
                          </Table.Cell>
                        </Table.Row>
                      ))}
                    </Table>
                  </>
                )}
              </Section>
              {can_create_weapons && (
                <Section title="> FEV WEAPONS">
                  <NoticeBox warning>
                    FEV weapons cause genetic damage. Karma
                    penalty: -15 per item.
                  </NoticeBox>
                  <Flex gap={1} wrap>
                    <Button
                      color="bad"
                      onClick={() =>
                        act('create_weapon', {
                          weapon_type: 'fev_grenade',
                        })}>
                      Synthesize FEV Grenade
                    </Button>
                    <Button
                      color="bad"
                      onClick={() =>
                        act('create_weapon', {
                          weapon_type: 'fev_dart',
                        })}>
                      Synthesize FEV Dart
                    </Button>
                    <Button
                      color="bad"
                      onClick={() =>
                        act('create_weapon', {
                          weapon_type: 'fev_vial',
                        })}>
                      Synthesize FEV Extract
                    </Button>
                  </Flex>
                </Section>
              )}
            </>
          )}

          <NoticeBox info>
            <Box bold>Important Notes:</Box>
            <Box>
              - Project effects are RANDOMIZED each round -
              no two tests are guaranteed the same
            </Box>
            <Box>
              - Strain stability affects predictability -
              higher is better
            </Box>
            <Box>
              - Side effects are RANDOM and can be severe
            </Box>
            <Box>
              - Super Mutant transformation is irreversible
            </Box>
          </NoticeBox>
        </Stack>
      </Window.Content>
    </Window>
  );
};
