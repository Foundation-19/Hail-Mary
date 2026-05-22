import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, Divider } from '../components';
import { Window } from '../layouts';

type LobbyMenuData = {
  character_name: string;
  game_state: string;
  is_observer: boolean;
  has_polls: boolean;
  is_interviewee: boolean;
  rules_accepted: boolean;
  current_slot: number;
  ready: boolean;
};

export const LobbyMenu = (props, context) => {
  const { act, data } = useBackend<LobbyMenuData>(context);
  const {
    character_name = 'WANDERER',
    game_state = 'pregame',
    has_polls = false,
    current_slot = 1,
    ready = false,
  } = data;

  const isPregame = game_state === 'pregame';
  const isRunning = game_state === 'running';

  return (
    <Window width={400} height={520} title="ROBCO TERMINAL" theme="fallout">
      <Window.Content scrollable>
        <Box className="LobbyMenu__container">
          <Box className="terminal-header">
            <Box className="LobbyMenu__header-line">
              ROBCO INDUSTRIES (TM) WASTELAND TERMINAL
            </Box>
            <Box className="LobbyMenu__subheader">
              SETTLEMENT REGISTRATION SYSTEM V3.1
            </Box>
          </Box>

          <Box className="LobbyMenu__section">
            <Box className="LobbyMenu__section-title">
              {'>'} USER IDENTIFICATION
            </Box>
            <Box className="terminal-divider" />
            <Flex direction="column" className="LobbyMenu__info">
              <Flex.Item className="LobbyMenu__info-row">
                <Box className="LobbyMenu__label">NAME:</Box>
                <Box className="LobbyMenu__value">{character_name}</Box>
              </Flex.Item>
              <Flex.Item className="LobbyMenu__info-row">
                <Box className="LobbyMenu__label">STATUS:</Box>
                <Box className="LobbyMenu__value" style={{ color: ready ? '#4cff4c' : '#e8a020' }}>
                  {ready ? 'READY' : 'NOT READY'}
                </Box>
              </Flex.Item>
              <Flex.Item className="LobbyMenu__info-row">
                <Box className="LobbyMenu__label">SLOT:</Box>
                <Box className="LobbyMenu__value">{current_slot}</Box>
              </Flex.Item>
            </Flex>
          </Box>

          <Box className="LobbyMenu__section">
            <Box className="LobbyMenu__section-title">
              {'>'} MAIN MENU
            </Box>
            <Box className="terminal-divider" />

            <Box className="LobbyMenu__menu">
              <Box className="LobbyMenu__menu-item" onClick={() => act('show_preferences')}>
                <Box className="LobbyMenu__menu-number">[1]</Box>
                <Box className="LobbyMenu__menu-text">CHARACTER CREATOR</Box>
              </Box>

              {isPregame && (
                <>
                  <Box className="LobbyMenu__status-message">
                    {'>'} AWAITING ROUND START...
                  </Box>
                  <Box className="LobbyMenu__menu-item" onClick={() => act('refresh')}>
                    <Box className="LobbyMenu__menu-number">[2]</Box>
                    <Box className="LobbyMenu__menu-text">REFRESH</Box>
                  </Box>
                  <Box className="LobbyMenu__menu-item" onClick={() => act('fix_chat')}>
                    <Box className="LobbyMenu__menu-number">[3]</Box>
                    <Box className="LobbyMenu__menu-text">FIX CHAT WINDOW</Box>
                  </Box>
                </>
              )}

              {isRunning && (
                <>
                  <Box className="LobbyMenu__menu-item LobbyMenu__menu-item--highlight" onClick={() => act('late_join')}>
                    <Box className="LobbyMenu__menu-number">[2]</Box>
                    <Box className="LobbyMenu__menu-text">JOIN GAME</Box>
                  </Box>
                  <Box className="LobbyMenu__menu-item" onClick={() => act('observe')}>
                    <Box className="LobbyMenu__menu-number">[3]</Box>
                    <Box className="LobbyMenu__menu-text">OBSERVE</Box>
                  </Box>
                  <Box className="LobbyMenu__menu-item" onClick={() => act('fix_chat')}>
                    <Box className="LobbyMenu__menu-number">[4]</Box>
                    <Box className="LobbyMenu__menu-text">FIX CHAT WINDOW</Box>
                  </Box>
                </>
              )}
            </Box>
          </Box>

          <Box className="LobbyMenu__section">
            <Box className="LobbyMenu__section-title">
              {'>'} LINKS
            </Box>
            <Box className="terminal-divider" />

            <Box className="LobbyMenu__menu">
              <Box className="LobbyMenu__menu-item" onClick={() => act('view_wiki')}>
                <Box className="LobbyMenu__menu-number">[W]</Box>
                <Box className="LobbyMenu__menu-text">WIKI</Box>
              </Box>
              <Box className="LobbyMenu__menu-item" onClick={() => act('show_rules')}>
                <Box className="LobbyMenu__menu-number">[R]</Box>
                <Box className="LobbyMenu__menu-text">SERVER RULES</Box>
              </Box>
              {has_polls && (
                <Box className="LobbyMenu__menu-item" onClick={() => act('show_polls')}>
                  <Box className="LobbyMenu__menu-number">[P]</Box>
                  <Box className="LobbyMenu__menu-text">PLAYER POLLS</Box>
                </Box>
              )}
            </Box>
          </Box>

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
