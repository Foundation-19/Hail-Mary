import { useBackend, useLocalState } from '../backend';
import { Button, Section, Table, Stack, NoticeBox, Flex, Box, NumberInput } from '../components';
import { Window } from '../layouts';

type EastwoodInnData = {
  daily_rate?: number;
  has_room?: boolean;
  my_room?: Room;
  rooms?: Room[];
};

type Room = {
  id?: string;
  name?: string;
  quality?: number;
  occupied?: boolean;
};

export const EastwoodInn = (props, context) => {
  const { act, data } = useBackend<EastwoodInnData>(context);

  const {
    daily_rate = 30,
    has_room,
    my_room,
    rooms = [],
  } = data;

  const [days, setDays] = useLocalState(context, 'days', 1);

  return (
    <Window theme="fallout" width={500} height={500}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="Eastwood Inn">
            <Box>Daily Rate: <b>{daily_rate} caps</b></Box>
          </Section>

          {has_room && my_room && (
            <Section title="Your Room">
              <NoticeBox success>You have rented {my_room.name}.</NoticeBox>
              <Button onClick={() => act('check_out', { room_id: my_room.id })}>
                Check Out
              </Button>
            </Section>
          )}

          <Section title="Available Rooms">
            <Flex align="center" gap="5px" mb={1}>
              <Box>Rent for:</Box>
              <NumberInput
                value={days}
                minValue={1}
                maxValue={7}
                step={1}
                onDrag={(e, value) => setDays(value)}
              />
              <Box>day(s) = {daily_rate * days} caps</Box>
            </Flex>
            <Table>
              <Table.Row header>
                <Table.Cell>Room</Table.Cell>
                <Table.Cell>Quality</Table.Cell>
                <Table.Cell>Status</Table.Cell>
                <Table.Cell>Actions</Table.Cell>
              </Table.Row>
              {rooms.map(room => (
                <Table.Row key={room.id}>
                  <Table.Cell>{room.name}</Table.Cell>
                  <Table.Cell>{room.quality === 2 ? 'Premium' : 'Standard'}</Table.Cell>
                  <Table.Cell>
                    {room.occupied ? 'Occupied' : 'Available'}
                  </Table.Cell>
                  <Table.Cell>
                    {!room.occupied && !has_room && (
                      <Button onClick={() => act('rent_room', { room_id: room.id, days: days })}>
                        Rent
                      </Button>
                    )}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
