import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, TextArea, Section } from '../components';
import { Window } from '../layouts';

type FlavorTextEditorData = {
  flavor_text: string;
};

export const FlavorTextEditor = (props, context) => {
  const { act, data } = useBackend<FlavorTextEditorData>(context);
  const { flavor_text = '' } = data;

  const [textInput, setTextInput] = useLocalState(context, 'textInput', flavor_text);

  return (
    <Window width={500} height={400} title="FLAVOR TEXT EDITOR" theme="fallout" resizable>
      <Window.Content scrollable>
        <Section title="ROBCO INDUSTRIES (TM) TERMINAL">
          <Box style={{ color: '#4cff4c', 'font-size': '12px', 'margin-bottom': '5px' }}>
            CHARACTER DESCRIPTION DATABASE
          </Box>
        </Section>

        <Section title="> ENTER DESCRIPTION BELOW" buttons={
          <Box style={{ color: '#888', 'font-size': '14px' }}>
            {textInput?.length || 0} / 2000
          </Box>
        }>
          <TextArea
            value={textInput}
            onInput={(_, v) => setTextInput(v)}
            fluid
            height="200px"
            maxLength={2000}
            style={{
              'font-family': 'VT323, monospace',
              'font-size': '16px',
              'background-color': '#050c05',
              'border': '1px solid #3ac83a',
              'color': '#a8d8a8',
            }}
          />
        </Section>

        <Section>
          <Flex justify="space-between">
            <Flex.Item>
              <Button
                content="> CANCEL"
                onClick={() => act('close')}
              />
            </Flex.Item>
            <Flex.Item>
              <Button
                content="> SAVE"
                color="good"
                onClick={() => {
                  act('set_flavor_text', { text: textInput });
                  act('close');
                }}
              />
            </Flex.Item>
          </Flex>
        </Section>
      </Window.Content>
    </Window>
  );
};
