import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, Input, Divider } from '../components';
import { Window } from '../layouts';

type RelationshipData = {
  relationships: RelationshipInfo[];
  relationship_types: string[];
};

type RelationshipInfo = {
  ckey: string;
  type: string;
  description: string;
  secret: boolean;
};

export const Relationships = (props, context) => {
  const { act, data } = useBackend<RelationshipData>(context);
  const {
    relationships = [],
    relationship_types = [],
  } = data;

  return (
    <Window width={600} height={500} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
          <span style={{ float: 'right' }}>VAULT-TEC CORP</span>
        </Box>

        <Section title="> YOUR RELATIONSHIPS">
          {relationships.length > 0 ? (
            relationships.map(rel => (
              <Box
                key={rel.ckey}
                style={{
                  border: '1px solid #1a5e38',
                  padding: '12px',
                  margin: '8px 0',
                  background: '#041a0e',
                }}
              >
                <Flex justify="space-between" align="center">
                  <Flex.Item>
                    <Box style={{ color: '#4cff4c', fontWeight: 'bold', fontSize: '1.1em' }}>{rel.ckey}</Box>
                    <Box style={{ color: rel.type === 'friend' ? '#4cff4c' : rel.type === 'enemy' ? '#ff3333' : '#ffaa00' }}>
                      {rel.type.toUpperCase()}
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    <Button content="[REMOVE]" color="bad" onClick={() => act('remove', { ckey: rel.ckey })} />
                  </Flex.Item>
                </Flex>
                {rel.description && (
                  <Box style={{ color: '#2a7a52', marginTop: '8px' }}>{rel.description}</Box>
                )}
                {rel.secret && (
                  <Box style={{ color: '#888', fontStyle: 'italic', marginTop: '5px' }}>(Secret)</Box>
                )}
              </Box>
            ))
          ) : (
            <Box style={{ color: '#2a7a52', textAlign: 'center', padding: '20px' }}>
              You have no relationships yet.
            </Box>
          )}
        </Section>

        <Divider />

        <Section title="> PROPOSE RELATIONSHIP">
          <Button fluid content="> PROPOSE NEW RELATIONSHIP" onClick={() => act('propose')} />
        </Section>

        <Box className="CharacterSetup__footer">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>
      </Window.Content>
    </Window>
  );
};
