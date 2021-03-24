import {
  ProjectTypeInput,
  ProjectTypeVariables,
  ListFilesOnDefaultBranchInput,
  ListFilesOnDefaultBranchVariables,
} from 'oneGraphStudio';

type ProjectType = 'next.js' | 'netlify/next.js' | 'netlify/*' | 'unknown';

function detectAppType(payload): ProjectType {
  const entries =
    payload?.ListFilesOnDefaultBranch?.data?.gitHub?.repository
      ?.defaultBranchRef?.target?.history?.edges[0]?.node?.tree?.entries;

  const hasNetlifyToml = entries?.some((e) => e.name === 'netlify.toml');
  const hasNetlifyFunctions = entries?.some(
    (e) => e.name === 'netlify-functions'
  );
  const hasSrcFunctions = entries?.some(
    (e) =>
      e.name === 'src' && e.object?.entries?.some((e) => e.name === 'functions')
  );
  const hastNextConfigJs = entries?.some((e) => e.name === 'next.config.js');

  if (hasNetlifyToml && hastNextConfigJs) {
    return 'netlify/next.js';
  } else if (hastNextConfigJs) {
    return 'next.js';
  } else if (hasNetlifyFunctions || hasSrcFunctions || hasNetlifyToml) {
    return 'netlify/*';
  } else {
    return 'unknown';
  }
}

export function makeVariablesForProjectType(
  payload: ProjectTypeInput
): ProjectTypeVariables {
  const projectType = detectAppType(payload);
  return { projectType: projectType };
}

export function makeVariablesForListFilesOnDefaultBranch(
  payload: ListFilesOnDefaultBranchInput
): ListFilesOnDefaultBranchVariables {
  return {};
}
