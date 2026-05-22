import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, TextArea } from '../components';

type CodexTerminalData = {
  user_record: CodexRecord;
  is_elder: boolean;
  is_command: boolean;
  rules: CodexRule[];
  pending_cases: CodexViolation[];
  recent_violations: CodexViolation[];
};

type CodexRecord = {
  ckey: string;
  strikes: number;
  status: string;
  status_name: string;
  violation_count: number;
};

type CodexRule = {
  id: string;
  name: string;
  description: string;
  severity: number;
  punishment: string;
};

type CodexViolation = {
  id: string;
  violator_ckey: string;
  rule_id: string;
  rule_name: string;
  reported_by: string;
  timestamp: string;
  evidence: string;
  status: string;
  punishment: string;
};

const getSeverityColor = (severity: number): string => {
  switch (severity) {
    case 1:
      return 'yellow';
    case 2:
      return 'orange';
    case 3:
      return 'red';
    default:
      return 'grey';
  }
};

const getStatusColor = (status: string): string => {
  switch (status) {
    case 'pending':
      return 'yellow';
    case 'reviewed':
      return 'blue';
    case 'punished':
      return 'red';
    case 'dismissed':
      return 'green';
    default:
      return 'grey';
  }
};

export const CodexTerminal = (props, context) => {
  const { act, data } = useBackend<CodexTerminalData>(context);
  const {
    user_record,
    is_elder,
    is_command,
    rules = [],
    pending_cases = [],
    recent_violations = [],
  } = data;

  return (
    <Window
      width={700}
      height={800}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="> BROTHERHOOD OF STEEL">
              <Box color="silver" fontSize="14px">
                CODEX ENFORCEMENT TERMINAL
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> THE CODEX">
              <Box italic color="grey" fontSize="13px" mb={2}>
                &quot;Preserve technology, protect the people, uphold the
                Brotherhood&apos;s mission above all else.&quot;
              </Box>
              <Box color="silver" fontSize="12px">
                The Codex is the sacred text of the Brotherhood. All members are
                bound by its rules and subject to its justice.
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> YOUR STANDING">
              <LabeledList>
                <LabeledList.Item label="Status">
                  <Box
                    color={user_record?.status === 'good_standing' ? 'green' : 'red'}
                    bold>
                    {user_record?.status_name || 'Unknown'}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Strikes">
                  <Box color={user_record?.strikes >= 3 ? 'red' : 'yellow'}>
                    {user_record?.strikes || 0}/5
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Violations">
                  <Box color="silver">{user_record?.violation_count || 0}</Box>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> CODEX RULES">
              <Stack vertical>
                {rules.map(rule => (
                  <Box key={rule.id} p={1} backgroundColor="rgba(50,50,50,0.5)" mb={1}>
                    <LabeledList>
                      <LabeledList.Item label="Rule">
                        <Box color={getSeverityColor(rule.severity)} bold>
                          {rule.name}
                        </Box>
                      </LabeledList.Item>
                      <LabeledList.Item label="Description">
                        <Box color="grey" fontSize="12px">{rule.description}</Box>
                      </LabeledList.Item>
                      <LabeledList.Item label="Severity">
                        <Box color={getSeverityColor(rule.severity)}>
                          {'!'.repeat(rule.severity)} Level {rule.severity}
                        </Box>
                      </LabeledList.Item>
                      <LabeledList.Item label="Punishment">
                        <Box color="silver" fontSize="12px">{rule.punishment}</Box>
                      </LabeledList.Item>
                    </LabeledList>
                  </Box>
                ))}
              </Stack>
            </Section>
          </Stack.Item>

          {is_command && (
            <Stack.Item>
              <Section title="> REPORT VIOLATION">
                <Box color="silver" fontSize="12px" mb={2}>
                  As command staff, you can report Codex violations.
                </Box>
                <LabeledList>
                  <LabeledList.Item label="Rule">
                    <Button
                      color="yellow"
                      onClick={() => act('select_rule')}>
                      Select Rule
                    </Button>
                  </LabeledList.Item>
                  <LabeledList.Item label="Accused">
                    <Button
                      color="red"
                      onClick={() => act('select_accused')}>
                      Select Player
                    </Button>
                  </LabeledList.Item>
                </LabeledList>
                <Box mt={2}>
                  <Button
                    color="red"
                    onClick={() => act('report_violation')}>
                    Submit Report
                  </Button>
                </Box>
              </Section>
            </Stack.Item>
          )}

          {is_elder && pending_cases.length > 0 && (
            <Stack.Item>
              <Section title="> PENDING CASES (Elder Only)">
                <Stack vertical>
                  {pending_cases.map(violation => (
                    <Box key={violation.id} p={1} backgroundColor="rgba(50,50,50,0.5)" mb={1}>
                      <LabeledList>
                        <LabeledList.Item label="Accused">
                          <Box color="red">{violation.violator_ckey}</Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Violation">
                          <Box color="yellow">{violation.rule_name}</Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Reported By">
                          <Box color="silver">{violation.reported_by}</Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Evidence">
                          <Box color="grey" fontSize="12px">{violation.evidence || 'None provided'}</Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Status">
                          <Box color={getStatusColor(violation.status)}>
                            {violation.status.toUpperCase()}
                          </Box>
                        </LabeledList.Item>
                      </LabeledList>
                      <Stack mt={1}>
                        <Stack.Item>
                          <Button
                            color="blue"
                            size="tiny"
                            onClick={() => act('review_case', {
                              violation_id: violation.id,
                            })}>
                            Review
                          </Button>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            color="red"
                            size="tiny"
                            onClick={() => act('punish_case', {
                              violation_id: violation.id,
                              punishment: 'Reprimand',
                            })}>
                            Punish
                          </Button>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            color="green"
                            size="tiny"
                            onClick={() => act('dismiss_case', {
                              violation_id: violation.id,
                            })}>
                            Dismiss
                          </Button>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            color="red"
                            size="tiny"
                            onClick={() => act('exile_player', {
                              target_ckey: violation.violator_ckey,
                            })}>
                            Exile
                          </Button>
                        </Stack.Item>
                      </Stack>
                    </Box>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {recent_violations.length > 0 && (
            <Stack.Item>
              <Section title="> YOUR RECENT VIOLATIONS">
                <Stack vertical>
                  {recent_violations.map(violation => (
                    <Box key={violation.id} p={1} backgroundColor="rgba(50,50,50,0.5)" mb={1}>
                      <LabeledList>
                        <LabeledList.Item label="Rule">
                          <Box color="yellow">{violation.rule_name}</Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Status">
                          <Box color={getStatusColor(violation.status)}>
                            {violation.status.toUpperCase()}
                          </Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Punishment">
                          <Box color="silver">{violation.punishment || 'Pending'}</Box>
                        </LabeledList.Item>
                      </LabeledList>
                    </Box>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
