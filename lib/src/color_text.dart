extension ColorString on String {
  String color(List<String> ansiMods) {
    return '${ansiMods.join('')}${this}$ansiReset';
  }
}

const String ansiReset = '\x1b[0m';
const String ansiBold = '\x1b[1m';
const String ansiFaint = '\x1b[2m';
const String ansiItalic = '\x1b[3m';
const String ansiUnderline = '\x1b[3m';

const String ansiGrayBg = '\x1b[100m';
const String ansiGray = '\x1b[90m';
const String ansiDarkGrayBg = '\x1b[40m';
const String ansiDarkGray = '\x1b[30m';

const String ansiRedBg = '\x1b[101m';
const String ansiRed = '\x1b[91m';
const String ansiDarkRedBg = '\x1b[41m';
const String ansiDarkRed = '\x1b[31m';

const String ansiGreenBg = '\x1b[102m';
const String ansiGreen = '\x1b[92m';
const String ansiDarkGreenBg = '\x1b[42m';
const String ansiDarkGreen = '\x1b[32m';

const String ansiYellowBg = '\x1b[103m';
const String ansiYellow = '\x1b[93m';
const String ansiDarkYellowBg = '\x1b[43m';
const String ansiDarkYellow = '\x1b[33m';

const String ansiBlueBg = '\x1b[104m';
const String ansiBlue = '\x1b[94m';
const String ansiDarkBlueBg = '\x1b[44m';
const String ansiDarkBlue = '\x1b[34m';

const String ansiPurpleBg = '\x1b[105m';
const String ansiPurple = '\x1b[95m';
const String ansiDarkPurpleBg = '\x1b[45m';
const String ansiDarkPurple = '\x1b[35m';

const String ansiCyanBg = '\x1b[106m';
const String ansiCyan = '\x1b[96m';
const String ansiDarkCyanBg = '\x1b[46m';
const String ansiDarkCyan = '\x1b[36m';

const String ansiWhiteBg = '\x1b[107m';
const String ansiWhite = '\x1b[97m';
const String ansiDarkWhiteBg = '\x1b[47m';
const String ansiDarkWhite = '\x1b[37m';
