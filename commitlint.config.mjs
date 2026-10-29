const stripGitComments = (raw) => {
  const lines = (raw ?? '').split('\n');
  const scissors = lines.findIndex((line) => /^# -+ >8 -+$/.test(line));
  return (scissors === -1 ? lines : lines.slice(0, scissors))
    .filter((line) => !line.startsWith('#'))
    .join('\n');
};

export default {
  extends: ['@commitlint/config-conventional'],
  plugins: [
    'commitlint-plugin-tense',
    {
      rules: {
        'subject-end-punctuation': ({ header }) => {
          const end = (header ?? '').trimEnd();
          return [!end.endsWith('?') && !end.endsWith('...'), 'subject may not end with question mark or ellipsis'];
        },
        'ascii-only': ({ raw }) => {
          const found = [...new Set([...stripGitComments(raw)].filter((c) => c.codePointAt(0) > 0x7f))];
          return [found.length === 0, `commit message must use ASCII characters only (found: ${found.join(' ')})`];
        },
      },
    },
  ],
  rules: {
    'type-enum': [2, 'always', ['feat', 'fix', 'docs', 'refactor', 'test', 'chore']],
    'header-max-length': [2, 'always', 50],
    'subject-case': [2, 'always', 'lower-case'],
    'ascii-only': [2, 'always'],
    'tense/subject-tense': [2, 'always', { allowedTenses: ['present-imperative'], firstOnly: true }],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'subject-end-punctuation': [2, 'always'],
    'body-max-line-length': [2, 'always', 72],
    'body-leading-blank': [2, 'always'],
    'footer-max-line-length': [2, 'always', 72],
    'footer-leading-blank': [2, 'always'],
  },
};
