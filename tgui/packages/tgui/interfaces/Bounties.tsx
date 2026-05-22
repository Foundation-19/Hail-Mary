import { useBackend } from '../backend';
import { Box, Button, Section, Flex, Divider } from '../components';
import { Window } from '../layouts';

type BountiesData = {
  your_bounty: number;
  bounties: BountyInfo[];
};

type BountyInfo = {
  ckey: string;
  amount: number;
  reason: string;
  placed_by: string;
  created_at: string;
};

export const Bounties = (props, context) => {
  const { act, data } = useBackend<BountiesData>(context);
  const {
    your_bounty = 0,
    bounties = [],
  } = data;

  return (
    <Window width={600} height={500} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
          <span style={{ float: 'right' }}>VAULT-TEC CORP</span>
        </Box>

        {your_bounty > 0 && (
          <Section title="> YOUR BOUNTY">
            <Box style={{ border: '2px solid #ff0000', padding: '15px', background: 'rgba(255,0,0,0.1)' }}>
              <Box style={{ color: '#ff0000', fontSize: '1.5em', fontWeight: 'bold' }}>{your_bounty} CAPS</Box>
              <Box style={{ color: '#ff6666' }}>Bounty hunters may be after you!</Box>
            </Box>
          </Section>
        )}

        <Section title={`> ACTIVE BOUNTIES (${bounties.length})`}>
          {bounties.length > 0 ? (
            bounties.map(b => (
              <Box
                key={b.ckey}
                style={{
                  border: '1px solid #663333',
                  padding: '12px',
                  margin: '8px 0',
                  background: '#2a1515',
                }}
              >
                <Box style={{ color: '#ff6666', fontWeight: 'bold', fontSize: '1.1em' }}>{b.ckey}</Box>
                <Box style={{ color: '#ffcc00', fontSize: '1.1em' }}>{b.amount} caps</Box>
                <Box style={{ color: '#996633', fontStyle: 'italic' }}>{b.reason}</Box>
                <Box style={{ color: '#664422', fontSize: '0.9em', marginTop: '5px' }}>Placed: {b.created_at}</Box>
              </Box>
            ))
          ) : (
            <Box style={{ color: '#4cff4c', textAlign: 'center', padding: '20px' }}>
              No active bounties in the wasteland. Good news!
            </Box>
          )}
        </Section>

        <Box className="CharacterSetup__footer">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>
      </Window.Content>
    </Window>
  );
};
