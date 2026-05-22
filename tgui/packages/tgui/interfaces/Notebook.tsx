import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, TextArea, Input, Divider } from '../components';
import { Window } from '../layouts';

type NotebookData = {
  entries: NotebookEntry[];
  max_entries: number;
};

type NotebookEntry = {
  id: number;
  text: string;
  is_public: boolean;
  timestamp: string;
};

export const Notebook = (props, context) => {
  const { act, data } = useBackend<NotebookData>(context);
  const {
    entries = [],
    max_entries = 50,
  } = data;

  const [newText, setNewText] = useLocalState(context, 'newText', '');
  const [isPublic, setIsPublic] = useLocalState(context, 'isPublic', false);

  return (
    <Window width={700} height={600} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
          <span style={{ float: 'right' }}>VAULT-TEC CORP</span>
        </Box>

        <Section title={`> MY NOTES (${entries.length}/${max_entries})`}>
          <Button content="> PUBLIC NOTES" onClick={() => act('view_public')} style={{ marginBottom: '10px' }} />
          
          {entries.length > 0 ? (
            entries.map(entry => (
              <Box
                key={entry.id}
                style={{
                  border: '1px solid #1a5e38',
                  padding: '10px',
                  margin: '6px 0',
                  background: '#041a0e',
                }}
              >
                <Flex justify="space-between" align="flex-start">
                  <Flex.Item grow>
                    <Box style={{ color: '#4cff4c' }}>{entry.text}</Box>
                    <Box style={{ color: '#2a7a52', fontSize: '0.85em', marginTop: '5px' }}>
                      {entry.timestamp}
                      {entry.is_public && <span style={{ color: '#ffaa00', marginLeft: '10px' }}>[PUBLIC]</span>}
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    <Button compact content="[X]" color="bad" onClick={() => act('delete', { id: entry.id })} />
                  </Flex.Item>
                </Flex>
              </Box>
            ))
          ) : (
            <Box style={{ color: '#2a7a52', textAlign: 'center', padding: '20px' }}>
              Your notebook is empty. Add an entry to get started!
            </Box>
          )}
        </Section>

        <Divider />

        <Section title="> ADD ENTRY">
          <TextArea
            value={newText}
            onInput={(_, v) => setNewText(v)}
            fluid
            rows={4}
            maxLength={500}
            placeholder="Write your note here..."
          />
          <Flex align="center" style={{ marginTop: '10px' }}>
            <Flex.Item>
              <Button
                content={isPublic ? 'PUBLIC' : 'PRIVATE'}
                selected={isPublic}
                onClick={() => setIsPublic(!isPublic)}
              />
            </Flex.Item>
            <Flex.Item grow>
              <Button
                fluid
                content="> ADD ENTRY"
                color="good"
                disabled={!newText || newText.length < 1}
                onClick={() => {
                  act('add', { text: newText, public: isPublic });
                  setNewText('');
                }}
                style={{ marginLeft: '10px' }}
              />
            </Flex.Item>
          </Flex>
        </Section>

        <Box className="CharacterSetup__footer">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>
      </Window.Content>
    </Window>
  );
};
