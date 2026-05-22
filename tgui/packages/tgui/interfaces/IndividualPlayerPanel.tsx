import { useBackend } from '../backend';
import { Section, Flex, Button, Box, Divider, Tabs, Stack, Input, NoticeBox } from '../components';
import { Window } from '../layouts';

type PlayerInfo = {
  name: string;
  real_name: string;
  key: string;
  ckey: string;
  ref: string;
  job: string;
  mob_type: string;
  has_client: boolean;
  rank: string;
  playtime: string;
  first_seen: string;
  account_date: string;
  byond_version: string;
  antag_rep: number;
  is_new_player: boolean;
  is_human: boolean;
  is_monkey: boolean;
  is_corgi: boolean;
  is_ai: boolean;
  is_cyborg: boolean;
  is_animal: boolean;
  has_mind: boolean;
  muted_ic: boolean;
  muted_ooc: boolean;
  muted_pray: boolean;
  muted_adminhelp: boolean;
  muted_deadchat: boolean;
  muted_all: boolean;
  jobban_ooc: boolean;
  jobban_looc: boolean;
  jobban_emote: boolean;
};

type Data = {
  player: PlayerInfo;
};

export const IndividualPlayerPanel = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { player } = data;

  return (
    <Window width={700} height={700} title="ROBCO TERMINAL - SUBJECT FILE" theme="fallout">
      <Window.Content scrollable>
        <Section title="SUBJECT IDENTIFICATION">
          <Stack vertical>
            <Stack.Item>
              <Box style={{ fontSize: '20px', color: '#6bff6b', fontWeight: 'bold' }}>
                {player?.name}
              </Box>
              {player?.has_client && (
                <Box style={{ opacity: 0.8 }}>
                  PLAYED BY: <Box as="span" style={{ color: '#4cff4c' }}>{player?.key}</Box>
                </Box>
              )}
            </Stack.Item>
            <Stack.Item>
              <Flex gap={1} wrap>
                <Button content="[VV]" onClick={() => act('view_vars', { ref: player?.ref })} />
                {player?.has_mind && (
                  <Button content="[TP]" onClick={() => act('traitor_panel', { ref: player?.ref })} />
                )}
                <Button content="[PM]" onClick={() => act('private_message', { ckey: player?.ckey })} />
                <Button content="[SM]" onClick={() => act('subtle_message', { ref: player?.ref })} />
                <Button content="[FLW]" onClick={() => act('follow', { ref: player?.ref })} />
                <Button content="[LOGS]" onClick={() => act('logs', { ref: player?.ref })} />
              </Flex>
            </Stack.Item>
          </Stack>
        </Section>

        {player?.has_client && (
          <Section title="ACCOUNT DATA">
            <Box style={{ lineHeight: '1.6' }}>
              <Box>RANK: <Box as="span" style={{ color: '#6bff6b' }}>{player?.rank}</Box></Box>
              <Box>PLAYTIME: {player?.playtime}</Box>
              <Box>FIRST SEEN: {player?.first_seen}</Box>
              <Box>ACCOUNT CREATED: {player?.account_date}</Box>
              <Box>BYOND VERSION: {player?.byond_version}</Box>
              <Box>ANTAG REPUTATION: <Box as="span" style={{ color: '#6bff6b' }}>{player?.antag_rep}</Box></Box>
              <Flex gap={1} mt={1}>
                <Button content="[+]" onClick={() => act('add_rep', { ref: player?.ref })} />
                <Button content="[-]" onClick={() => act('sub_rep', { ref: player?.ref })} />
                <Button content="[SET]" onClick={() => act('set_rep', { ref: player?.ref })} />
                <Button content="[0]" onClick={() => act('zero_rep', { ref: player?.ref })} />
              </Flex>
            </Box>
          </Section>
        )}

        <Section title="ADMINISTRATIVE ACTIONS">
          <Stack vertical gap={1}>
            <Stack.Item>
              <Flex gap={1} wrap>
                <Button content="> KICK" color="danger" onClick={() => act('kick', { ref: player?.ref })} />
                <Button content="> BAN" color="danger" onClick={() => act('ban', { ref: player?.ref })} />
                <Button content="> JOBBAN" onClick={() => act('jobban', { ref: player?.ref })} />
                <Button content="> IDENTITY BAN" onClick={() => act('identity_ban', { ref: player?.ref })} />
              </Flex>
            </Stack.Item>
            <Stack.Item>
              <Box>MUTE STATUS:</Box>
              <Flex gap={1} wrap>
                <Button 
                  content={player?.muted_ic ? "[IC MUTED]" : "[IC]"}
                  color={player?.muted_ic ? "danger" : "default"}
                  onClick={() => act('mute', { ckey: player?.ckey, type: 'ic' })}
                />
                <Button 
                  content={player?.muted_ooc ? "[OOC MUTED]" : "[OOC]"}
                  color={player?.muted_ooc ? "danger" : "default"}
                  onClick={() => act('mute', { ckey: player?.ckey, type: 'ooc' })}
                />
                <Button 
                  content={player?.muted_pray ? "[PRAY MUTED]" : "[PRAY]"}
                  color={player?.muted_pray ? "danger" : "default"}
                  onClick={() => act('mute', { ckey: player?.ckey, type: 'pray' })}
                />
                <Button 
                  content={player?.muted_adminhelp ? "[AHELP MUTED]" : "[AHELP]"}
                  color={player?.muted_adminhelp ? "danger" : "default"}
                  onClick={() => act('mute', { ckey: player?.ckey, type: 'adminhelp' })}
                />
                <Button 
                  content={player?.muted_all ? "[ALL MUTED]" : "[ALL]"}
                  color={player?.muted_all ? "danger" : "default"}
                  onClick={() => act('mute', { ckey: player?.ckey, type: 'all' })}
                />
              </Flex>
            </Stack.Item>
            <Stack.Item>
              <Button content="> NOTES" onClick={() => act('notes', { ckey: player?.ckey })} />
              <Button content="> PRISON" onClick={() => act('prison', { ref: player?.ref })} />
              <Button content="> SEND TO LOBBY" onClick={() => act('lobby', { ref: player?.ref })} />
            </Stack.Item>
          </Stack>
        </Section>

        <Section title="TELEPORTATION">
          <Flex gap={1}>
            <Button content="> JUMP TO" onClick={() => act('jump_to', { ref: player?.ref })} />
            <Button content="> GET" onClick={() => act('get', { ref: player?.ref })} />
            <Button content="> SEND TO" onClick={() => act('send_to', { ref: player?.ref })} />
          </Flex>
        </Section>

        {!player?.is_new_player && (
          <Section title="MEDICAL">
            <Flex gap={1}>
              <Button content="> HEAL" color="good" onClick={() => act('heal', { ref: player?.ref })} />
              <Button content="> SLEEP" onClick={() => act('sleep', { ref: player?.ref })} />
            </Flex>
          </Section>
        )}

        {player?.has_client && !player?.is_new_player && (
          <Section title="TRANSFORMATION">
            <Box mb={1}>PRIMARY:</Box>
            <Flex gap={1} wrap mb={1}>
              {!player?.is_human && (
                <Button content="> HUMANIZE" onClick={() => act('transform', { type: 'human', ref: player?.ref })} />
              )}
              {!player?.is_monkey && (
                <Button content="> MONKEYIZE" onClick={() => act('transform', { type: 'monkey', ref: player?.ref })} />
              )}
              {!player?.is_corgi && (
                <Button content="> CORGIZE" onClick={() => act('transform', { type: 'corgi', ref: player?.ref })} />
              )}
              {player?.is_human && (
                <>
                  <Button content="> MAKE AI" onClick={() => act('transform', { type: 'ai', ref: player?.ref })} />
                  <Button content="> MAKE CYBORG" onClick={() => act('transform', { type: 'cyborg', ref: player?.ref })} />
                </>
              )}
            </Flex>
            <Box mb={1}>SIMPLE:</Box>
            <Flex gap={1} wrap>
              <Button content="> OBSERVER" onClick={() => act('simple_make', { type: 'observer', ref: player?.ref })} />
              <Button content="> ROBOT" onClick={() => act('simple_make', { type: 'robot', ref: player?.ref })} />
              <Button content="> CAT" onClick={() => act('simple_make', { type: 'cat', ref: player?.ref })} />
              <Button content="> CRAB" onClick={() => act('simple_make', { type: 'crab', ref: player?.ref })} />
            </Flex>
          </Section>
        )}

        <Section title="OTHER ACTIONS">
          <Flex gap={1} wrap>
            <Button content="> FORCE SPEECH" onClick={() => act('force_speech', { ref: player?.ref })} />
            <Button content="> NARRATE TO" onClick={() => act('narrate', { ref: player?.ref })} />
            <Button content="> THUNDERDOME 1" onClick={() => act('tdome', { which: 1, ref: player?.ref })} />
            <Button content="> THUNDERDOME 2" onClick={() => act('tdome', { which: 2, ref: player?.ref })} />
          </Flex>
        </Section>

        <Box style={{ opacity: 0.5, fontSize: '12px', marginTop: '10px' }}>
          MOB TYPE: {player?.mob_type}
        </Box>
      </Window.Content>
    </Window>
  );
};
