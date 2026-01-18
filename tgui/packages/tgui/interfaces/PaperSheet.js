/**
 * @file
 * @copyright 2020 WarlockD (https://github.com/warlockd)
 * @license MIT
 */

import { classes } from 'common/react';
import { Component } from 'inferno';
import { marked } from 'marked';
import { useBackend } from '../backend';
import { Box, Flex, Tabs, TextArea } from '../components';
import { Window } from '../layouts';
import { clamp } from 'common/math';
import { sanitizeText } from '../sanitize';

const MAX_PAPER_LENGTH = 9000;

const textWidth = (text, font, fontsize) => {
  font = fontsize + "px " + font;
  const c = document.createElement('canvas');
  const ctx = c.getContext("2d");
  ctx.font = font;
  const width = ctx.measureText(text).width;
  return width;
};

const setFontinText = (text, font, color, bold=false) => {
  return "<span style=\""
    + "color:" + color + ";"
    + "font-family:'" + font + "';"
    + ((bold) ? "font-weight: bold;" : "")
    + "\">" + text + "</span>";
};

const createIDHeader = index => {
  return "paperfield_" + index;
};

const field_regex = /\[(_+)\]/g;
const field_tag_regex = /\[<input\s+(?!disabled)(.*?)\s+id="(?<id>paperfield_\d+)"(.*?)\/>\]/gm;
const sign_regex = /%s(?:ign)?(?:\s|$)?/ig;

const createInputField = (length, width, font, fontsize, color, id) => {
  return "[<input "
      + "type=\"text\" "
      + "style=\""
      + "font:'" + fontsize + "px " + font + "';"
      + "color:" + color + ";"
      + "min-width:" + width + ";"
      + "max-width:" + width + ";"
      + "\" "
      + "id=\"" + id + "\" "
      + "maxlength=" + length +" "
      + "size=" + length + " "
      + "/>]";
};

const createFields = (txt, font, fontsize, color, counter) => {
  const ret_text = txt.replace(field_regex, (match, p1, offset, string) => {
    const width = textWidth(match, font, fontsize) + "px";
    return createInputField(p1.length, width, font, fontsize, color, createIDHeader(counter++));
  });
  return { counter, text: ret_text };
};

const signDocument = (txt, color, user) => {
  return txt.replace(sign_regex, () => {
    return setFontinText(user, "Times New Roman", color, true);
  });
};

const run_marked_default = value => {
  const walkTokens = token => {
    switch (token.type) {
      case 'url':
      case 'autolink':
      case 'reflink':
      case 'link':
      case 'image':
        token.type = 'text';
        token.href = "";
        break;
    }
  };
  return marked(value, {
    breaks: true,
    smartypants: true,
    smartLists: true,
    walkTokens,
    baseUrl: 'thisshouldbreakhttp',
  });
};

const checkAllFields = (txt, font, color, user_name, bold=false) => {
  let matches;
  let values = {};
  let replace = [];

  while ((matches = field_tag_regex.exec(txt)) !== null) {
    const full_match = matches[0];
    const id = matches.groups.id;
    if (id) {
      const dom = document.getElementById(id);
      const dom_text = dom && dom.value ? dom.value : "";
      if (dom_text.length === 0) {
        continue;
      }
      const sanitized_text = sanitizeText(dom.value.trim(), []);
      if (sanitized_text.length === 0) {
        continue;
      }

      const target = dom.cloneNode(true);

      if (sanitized_text.match(sign_regex)) {
        target.style.fontFamily = "Times New Roman";
        bold = true;
        target.defaultValue = user_name;
      } else {
        target.style.fontFamily = font;
        target.defaultValue = sanitized_text;
      }
      if (bold) {
        target.style.fontWeight = "bold";
      }
      target.style.color = color;
      target.disabled = true;
      const wrap = document.createElement('div');
      wrap.appendChild(target);
      values[id] = sanitized_text;
      replace.push({ value: "[" + wrap.innerHTML + "]", raw_text: full_match });
    }
  }
  if (replace.length > 0) {
    for (const o of replace) {
      txt = txt.replace(o.raw_text, o.value);
    }
  }
  return { text: txt, fields: values };
};

const pauseEvent = e => {
  if (e.stopPropagation) { e.stopPropagation(); }
  if (e.preventDefault) { e.preventDefault(); }
  e.cancelBubble=true;
  e.returnValue=false;
  return false;
};

const createPreview = (
  value,
  text,
  do_fields = false,
  field_counter,
  color,
  font,
  user_name,
  is_crayon = false,
) => {
  const out = { text: text };

  value = value.trim();
  if (value.length > 0) {
    value += value[value.length - 1] === "\n" ? " \n" : "\n \n";

    const sanitized_text = sanitizeText(value, []);
    const signed_text = signDocument(sanitized_text, color, user_name);
    const fielded_text = createFields(signed_text, font, 12, color, field_counter);
    const formatted_text = run_marked_default(fielded_text.text);
    const fonted_text = setFontinText(formatted_text, font, color, is_crayon);

    out.text += fonted_text;
    out.field_counter = fielded_text.counter;
  }

  if (do_fields) {
    const final_processing = checkAllFields(out.text, font, color, user_name, is_crayon);
    out.text = final_processing.text;
    out.form_fields = final_processing.fields;
  }
  return out;
};

// Components
const Stamp = (props, context) => {
  const { image, opacity } = props;
  const stamp_transform = {
    'left': image.x + 'px',
    'top': image.y + 'px',
    'transform': 'rotate(' + image.rotate + 'deg)',
    'opacity': opacity || 1.0,
  };
  return (
    <div
      id="stamp"
      className={classes(['Paper__Stamp', image.sprite])}
      style={stamp_transform} />
  );
};

const setInputReadonly = (text, readonly) => {
  return readonly
    ? text.replace(/<input\s[^d]/g, '<input disabled ')
    : text.replace(/<input\sdisabled\s/g, '<input ');
};

const PaperSheetView = (props, context) => {
  const { value = "", stamps = [], backgroundColor, readOnly } = props;
  const stamp_list = stamps;
  const text_html = {
    __html: '<span class="paper-text">' + setInputReadonly(value, readOnly) + '</span>',
  };
  return (
    <Box position="relative" backgroundColor={backgroundColor} width="100%" height="100%">
      <Box
        className="Paper__Page"
        fillPositionedParent
        width="100%"
        height="100%"
        dangerouslySetInnerHTML={text_html}
        p="10px" />
      {stamp_list.map((o, i) => (
        <Stamp key={o[0] + i} image={{ sprite: o[0], x: o[1], y: o[2], rotate: o[3] }} />
      ))}
    </Box>
  );
};

class PaperSheetStamper extends Component {
  constructor(props, context) {
    super(props, context);
    this.state = { x: 0, y: 0, rotate: 0 };

    this.handleMouseMove = e => {
      const pos = this.findStampPosition(e);
      if (!pos) { return; }
      pauseEvent(e);
      this.setState({ x: pos[0], y: pos[1], rotate: pos[2] });
    };

    this.handleMouseClick = e => {
      if (e.pageY <= 30) { return; }
      const { act, data } = useBackend(this.context);
      const stamp_obj = {
        x: this.state.x,
        y: this.state.y,
        r: this.state.rotate,
        stamp_class: this.props.stamp_class,
        stamp_icon_state: data.stamp_icon_state,
      };
      act("stamp", stamp_obj);
    };
  }

  findStampPosition(e) {
    let rotating;
    const windowRef = document.querySelector('.Layout__content');
    if (e.shiftKey) {
      rotating = true;
    }

    if (document.getElementById("stamp")) {
      const stamp = document.getElementById("stamp");
      const stampHeight = stamp.clientHeight;
      const stampWidth = stamp.clientWidth;

      const currentHeight = rotating ? this.state.y : e.pageY - windowRef.scrollTop - stampHeight;
      const currentWidth = rotating ? this.state.x : e.pageX - (stampWidth / 2);

      const widthMin = 0;
      const heightMin = 0;
      const widthMax = (windowRef.clientWidth) - (stampWidth);
      const heightMax = (windowRef.clientHeight - windowRef.scrollTop) - (stampHeight);

      const radians = Math.atan2(e.pageX - currentWidth, e.pageY - currentHeight);
      const rotate = rotating ? (radians * (180 / Math.PI) * -1) : this.state.rotate;

      const pos = [
        clamp(currentWidth, widthMin, widthMax),
        clamp(currentHeight, heightMin, heightMax),
        rotate,
      ];
      return pos;
    }
  }

  componentDidMount() {
    document.addEventListener("mousemove", this.handleMouseMove);
    document.addEventListener("click", this.handleMouseClick);
  }

  componentWillUnmount() {
    document.removeEventListener("mousemove", this.handleMouseMove);
    document.removeEventListener("click", this.handleMouseClick);
  }

  render() {
    const { value, stamp_class, stamps } = this.props;
    const stamp_list = stamps || [];
    const current_pos = {
      sprite: stamp_class,
      x: this.state.x,
      y: this.state.y,
      rotate: this.state.rotate,
    };
    return (
      <>
        <PaperSheetView readOnly value={value} stamps={stamp_list} />
        <Stamp active_stamp opacity={0.5} image={current_pos} />
      </>
    );
  }
}

class PaperSheetEdit extends Component {
  constructor(props, context) {
    super(props, context);

    this.state = {
      previewSelected: 'Preview',
      old_text: props.value || '',
      counter: props.counter || 0,
      textarea_text: '',
      combined_text: props.value || '',
    };
  }

  createPreviewFromData(value, do_fields = false) {
    const { data } = useBackend(this.context);
    return createPreview(
      value,
      this.state.old_text,
      do_fields,
      this.state.counter,
      data.pen_color,
      data.pen_font,
      data.edit_usr,
      data.is_crayon
    );
  }

  onInputHandler(e, value) {
    if (value !== this.state.textarea_text) {
      const { data } = useBackend(this.context);
      const maxLength = data.max_length || MAX_PAPER_LENGTH;
      const combined_length = this.state.old_text.length + value.length;

      if (combined_length > maxLength) {
        if (combined_length - maxLength >= value.length) {
          value = '';
        } else {
          value = value.substr(0, value.length - (combined_length - maxLength));
        }
        if (value === this.state.textarea_text) {
          return;
        }
      }

      this.setState(() => ({
        textarea_text: value,
        combined_text: this.createPreviewFromData(value).text,
      }));
    }
  }

finalUpdate(new_text) {
  const { act, data } = useBackend(this.context);
  const final_processing = this.createPreviewFromData(new_text, true);

  act('save', {
    text: new_text,
    field_counter: final_processing.field_counter,
    fields: final_processing.form_fields || {},
    pen_font: data.pen_font,
    pen_color: data.pen_color,
    is_crayon: data.is_crayon
  });

  this.setState(() => ({
    textarea_text: '',
    previewSelected: 'save',
    combined_text: final_processing.text,
    old_text: final_processing.text,
    counter: final_processing.field_counter,
  }));
}

  render() {
    const { textColor, fontFamily, stamps, backgroundColor } = this.props;

    return (
      <Flex direction="column" fillPositionedParent>
        <Flex.Item>
          <Tabs>
            <Tabs.Tab
              key="marked_edit"
              textColor={'black'}
              backgroundColor={this.state.previewSelected === 'Edit' ? 'grey' : 'white'}
              selected={this.state.previewSelected === 'Edit'}
              onClick={() => this.setState({ previewSelected: 'Edit' })}>
              Edit
            </Tabs.Tab>
            <Tabs.Tab
              key="marked_preview"
              textColor={'black'}
              backgroundColor={this.state.previewSelected === 'Preview' ? 'grey' : 'white'}
              selected={this.state.previewSelected === 'Preview'}
              onClick={() =>
                this.setState(() => ({
                  previewSelected: 'Preview',
                  textarea_text: this.state.textarea_text,
                  combined_text: this.createPreviewFromData(this.state.textarea_text).text,
                }))
              }>
              Preview
            </Tabs.Tab>
            <Tabs.Tab
              key="marked_done"
              textColor={'black'}
              backgroundColor={
                this.state.previewSelected === 'confirm' ? 'red' :
                this.state.previewSelected === 'save' ? 'grey' : 'white'
              }
              selected={this.state.previewSelected === 'confirm' || this.state.previewSelected === 'save'}
              onClick={() => {
                if (this.state.previewSelected === 'confirm') {
                  this.finalUpdate(this.state.textarea_text);
                } else if (this.state.previewSelected === 'Edit') {
                  this.setState(() => ({
                    previewSelected: 'confirm',
                    textarea_text: this.state.textarea_text,
                    combined_text: this.createPreviewFromData(this.state.textarea_text).text,
                  }));
                } else {
                  this.setState({ previewSelected: 'confirm' });
                }
              }}>
              {this.state.previewSelected === 'confirm' ? 'Confirm' : 'Save'}
            </Tabs.Tab>
          </Tabs>
        </Flex.Item>
        <Flex.Item grow={1} basis={1}>
          {(this.state.previewSelected === 'Edit' && (
            <TextArea
              value={this.state.textarea_text}
              textColor={textColor}
              fontFamily={fontFamily}
              height={(window.innerHeight - 80) + 'px'}
              backgroundColor={backgroundColor}
              onInput={this.onInputHandler.bind(this)} />
          )) || (
            <PaperSheetView
              value={this.state.combined_text}
              stamps={stamps}
              fontFamily={fontFamily}
              textColor={textColor} />
          )}
        </Flex.Item>
      </Flex>
    );
  }
}

export const PaperSheet = (props, context) => {
  const { data } = useBackend(context);
  const {
    edit_mode,
    text,
    paper_color = 'white',
    pen_color = 'black',
    pen_font = 'Verdana',
    stamps,
    stamp_class,
    sizeX,
    sizeY,
    name,
    add_text,
    add_font,
    add_color,
    add_sign,
    add_crayon,
    field_counter,
    form_fields,
    field_fonts,
    field_colors,
  } = data;

  // Build the formatted text from the stored formatting arrays
  const values = { text: "", field_counter: field_counter };

  if (add_text && add_text.length > 0) {
    // Process each saved text segment with its original formatting
    for (let index = 0; index < add_text.length; index++) {
      const used_color = add_color[index];
      const used_font = add_font[index];
      const used_sign = add_sign[index];
      const is_crayon = add_crayon ? add_crayon[index] : false;

      const processing = createPreview(
        add_text[index],
        values.text,
        false,
        values.field_counter,
        used_color,
        used_font,
        used_sign,
        is_crayon
      );
      values.text = processing.text;
      values.field_counter = processing.field_counter;
    }

    // If we have saved form field data, inject it with styling
    if (form_fields && Object.keys(form_fields).length > 0) {
      for (const field_id in form_fields) {
        const field_value = form_fields[field_id];
        const saved_font = field_fonts?.[field_id] || 'Verdana';
        const saved_color = field_colors?.[field_id] || '#000000';

        // More robust regex to find the input field
        const field_regex = new RegExp(
          `\\[<input[^>]*id="${field_id}"[^>]*>\\]`,
          'g'
        );

        values.text = values.text.replace(field_regex, (match) => {
          // Parse the existing input tag
          const inputMatch = match.match(/<input([^>]*)>/);
          if (!inputMatch) return match;

          let inputAttrs = inputMatch[1];

          // Update or add the value attribute
          if (inputAttrs.includes('value=')) {
            inputAttrs = inputAttrs.replace(/value="[^"]*"/, `value="${field_value}"`);
          } else {
            inputAttrs += ` value="${field_value}"`;
          }

          // Update the style to include saved font and color
          if (inputAttrs.includes('style=')) {
            inputAttrs = inputAttrs.replace(
              /style="([^"]*)"/,
              (styleMatch, existingStyle) => {
                // Remove existing color and font-family, then add new ones
                let cleanStyle = existingStyle
                  .replace(/color:[^;]*;?/g, '')
                  .replace(/font-family:[^;]*;?/g, '')
                  .replace(/font:[^;]*;?/g, '');
                return `style="${cleanStyle};color:${saved_color};font-family:'${saved_font}';"`;
              }
            );
          }

          // Add disabled attribute
          if (!inputAttrs.includes('disabled')) {
            inputAttrs = ' disabled' + inputAttrs;
          }

          return `[<input${inputAttrs}>]`;
        });
      }
    }

  } else if (text && text.length > 0) {
    values.text = sanitizeText(text);
  }

  const stamp_list = !stamps ? [] : stamps;

  const decide_mode = (mode) => {
    switch (mode) {
      case 0:  // Reading mode
        return (
          <PaperSheetView value={values.text} stamps={stamp_list} readOnly />
        );
      case 1:  // Edit mode
        return (
          <PaperSheetEdit
            value={values.text}
            counter={values.field_counter}
            textColor={pen_color}
            fontFamily={pen_font}
            stamps={stamp_list}
            backgroundColor={paper_color}
          />
        );
      case 2:  // Stamp mode
        return (
          <PaperSheetStamper
            value={values.text}
            stamps={stamp_list}
            stamp_class={stamp_class}
          />
        );
      default:
        return 'ERROR ERROR WE CANNOT BE HERE!!';
    }
  };

  return (
    <Window
      title={name}
      theme="paper"
      width={sizeX || 400}
      height={sizeY || 500}>
      <Window.Content backgroundColor={paper_color} scrollable>
        <Box id="page" fitted fillPositionedParent>
          {decide_mode(edit_mode)}
        </Box>
      </Window.Content>
    </Window>
  );
};
