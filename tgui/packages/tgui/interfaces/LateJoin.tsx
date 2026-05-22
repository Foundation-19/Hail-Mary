import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, Divider } from '../components';
import { Window } from '../layouts';

type JobData = {
  title: string;
  current: number;
  total: number;
  available: boolean;
  locked: boolean;
  lock_reason: string;
};

type FactionData = {
  name: string;
  jobs: JobData[];
};

type LateJoinData = {
  round_duration: string;
  evacuation_status: string;
  factions: FactionData[];
};

export const LateJoin = (props, context) => {
  const { act, data } = useBackend<LateJoinData>(context);
  const {
    round_duration = '',
    evacuation_status = '',
    factions = [],
  } = data;

  const [selectedFaction, setSelectedFaction] = useLocalState(context, 'selFaction', '');

  let globalJobIndex = 1;

  return (
    <Window width={900} height={700} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="LateJoin__container">
          <Box className="terminal-header">
            <Box className="LateJoin__header-line">
              SETTLEMENT PERSONNEL ASSIGNMENT TERMINAL
              <Button content="[X]" color="bad" onClick={() => act('close')} style={{ float: 'right' }} />
            </Box>
            <Box className="LateJoin__subheader">
              ROBCO INDUSTRIES WORKFORCE MANAGEMENT SYSTEM
            </Box>
          </Box>

          <Box className="LateJoin__status-bar">
            <Flex justify="space-between">
              <Flex.Item className="LateJoin__status-item">
                ROUND TIME: {round_duration}
              </Flex.Item>
              {evacuation_status && (
                <Flex.Item className="LateJoin__status-item LateJoin__status-item--alert">
                  {evacuation_status}
                </Flex.Item>
              )}
            </Flex>
          </Box>

          <Box className="LateJoin__section">
            <Box className="LateJoin__section-title">
              {'>'} AVAILABLE POSITIONS
            </Box>
            <Box className="terminal-divider" />
          </Box>

          {factions.map(faction => (
            <Box key={faction.name} className="LateJoin__faction">
              <Box className="LateJoin__faction-header">
                {faction.name}
              </Box>
              <Box className="LateJoin__faction-jobs">
                {faction.jobs.map(job => {
                  const jobNum = globalJobIndex++;
                  return (
                    <Flex
                      key={job.title}
                      align="center"
                      className="LateJoin__job-row"
                      onClick={() => {
                        if (!job.locked && job.available) {
                          act('join_job', { job: job.title });
                        }
                      }}
                    >
                      <Flex.Item className="LateJoin__job-number">
                        [{String(jobNum).padStart(2, '0')}]
                      </Flex.Item>
                      <Flex.Item grow className={`LateJoin__job-title ${job.locked ? 'LateJoin__job-title--locked' : !job.available ? 'LateJoin__job-title--full' : ''}`}>
                        {job.title}
                      </Flex.Item>
                      <Flex.Item className="LateJoin__job-status">
                        {job.locked ? (
                          <Box className="LateJoin__status LateJoin__status--locked" title={job.lock_reason}>
                            LOCKED
                          </Box>
                        ) : job.available ? (
                          <Box className="LateJoin__status LateJoin__status--available">
                            {job.current}/{job.total === -1 ? '∞' : job.total}
                          </Box>
                        ) : (
                          <Box className="LateJoin__status LateJoin__status--full">
                            FULL
                          </Box>
                        )}
                      </Flex.Item>
                    </Flex>
                  );
                })}
              </Box>
            </Box>
          ))}

          <Box className="terminal-footer">
            <Flex justify="space-between">
              <Flex.Item>ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL</Flex.Item>
              <Flex.Item>
                <Box className="terminal-cursor" />
              </Flex.Item>
            </Flex>
          </Box>
        </Box>
      </Window.Content>
    </Window>
  );
};
