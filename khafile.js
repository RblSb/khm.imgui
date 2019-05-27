let project = new Project('Empty');
project.addAssets('res/**', {
	nameBaseDir: 'res',
	destination: '{dir}/{name}',
	name: '{dir}/{name}'
});
project.addSources('src');
project.addParameter('-dce full');
project.addDefine('analyzer-optimize');
project.addDefine('kha_no_ogg');

resolve(project);
