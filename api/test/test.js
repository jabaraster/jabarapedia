const sut = require('../.webpack/dao')

sut.updateLanguage({
    meta: {
        lightWeight: false,
        staticTyping: true,
        functional: false,
        objectOriented: true,
    },
    name: 'Java',
    path: 'java',
    impression: 'So old...',
})
    .then(res => {
        console.log(res)
    })
    .catch(err => {
        console.log('!!!!!!!!!!')
        console.log(err)
    })