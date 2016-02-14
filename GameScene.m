//
//  GameScene.m
//  TrickyMouse
//
//  Created by Tongtong Xu on 12/28/15.
//  Copyright (c) 2015 Tongtong Xu. All rights reserved.
//

#import "GameScene.h"
@interface GameScene ()<SKPhysicsContactDelegate>{
    SKSpriteNode* _mouse;
    BOOL _canRestart;
    SKColor* _skyColor;
    SKNode* _moving;
    SKTexture* _pipeTexture1;
    SKTexture* _pipeTexture2;
    SKAction* _movePipesAndReset;
    SKNode* _pipes;
}
@property (nonatomic) SKSpriteNode * mouse;
@end


@implementation GameScene

static const uint32_t mouseCategory = 1 << 0;
static const uint32_t worldCategory = 1 << 1;
static const uint32_t pipeCategory = 1 << 2;
static const uint32_t scoreCategory = 1 << 3;

static NSInteger const kVerticalPipeGap = 100;

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        _canRestart = NO;
        
        // Add Background
        _skyColor = [SKColor colorWithRed:52.0/255.0 green:44.0/255.0 blue:99.0/255.0 alpha:1.0];
        [self setBackgroundColor:_skyColor];
        
        _pipes = [SKNode node];
        [self addChild:_pipes];

        // Add mouse texture (horizontal)
        SKTexture* mouseTexture1 = [SKTexture textureWithImageNamed:@"mouseHor4"];
        mouseTexture1.filteringMode = SKTextureFilteringNearest;
        SKTexture* mouseTexture2 = [SKTexture textureWithImageNamed:@"mouseHor3"];
        mouseTexture2.filteringMode = SKTextureFilteringNearest;
        //SKTexture* mouseTexture3 = [SKTexture textureWithImageNamed:@"mouseHor3"];
        //mouseTexture3.filteringMode = SKTextureFilteringNearest;
        
        SKAction* flap = [SKAction repeatActionForever:[SKAction animateWithTextures:@[mouseTexture1, mouseTexture2] timePerFrame:0.1]];
        
        _mouse = [SKSpriteNode spriteNodeWithTexture:mouseTexture1];
        [_mouse setScale:0.3];
        _mouse.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
        //_mouse.position = CGPointMake(100,100);
        [_mouse runAction:flap];
        
        //_mouse.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_mouse.size.height / 2];
        _mouse.physicsBody.dynamic = YES;
        _mouse.physicsBody.allowsRotation = NO;
        _mouse.physicsBody.categoryBitMask = mouseCategory;
        _mouse.physicsBody.collisionBitMask = worldCategory | pipeCategory;
        _mouse.physicsBody.contactTestBitMask = worldCategory | pipeCategory;

        //self.mouse.position = CGPointMake(100, 100);
        [self addChild:_mouse];
        
        //Add trash ground
        SKTexture* groundTexture = [SKTexture textureWithImageNamed:@"Skyline"];
        groundTexture.filteringMode = SKTextureFilteringNearest;
        
        SKAction* moveGroundSprite = [SKAction moveByX:-groundTexture.size.width*2 y:0 duration:0.02 * groundTexture.size.width*2];
        SKAction* resetGroundSprite = [SKAction moveByX:groundTexture.size.width*2 y:0 duration:0];
        SKAction* moveGroundSpritesForever = [SKAction repeatActionForever:[SKAction sequence:@[moveGroundSprite, resetGroundSprite]]];
        
        for( int i = 0; i < 2 + self.frame.size.width / ( groundTexture.size.width * 2 ); ++i ) {
            // Create the sprite
            SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture:groundTexture];
            [sprite setScale:2.0];
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2);
            [sprite runAction:moveGroundSpritesForever];
            [self addChild:sprite];
        }
        

        _pipeTexture1 = [SKTexture textureWithImageNamed:@"soil"];
        _pipeTexture1.filteringMode = SKTextureFilteringNearest;
        _pipeTexture2 = [SKTexture textureWithImageNamed:@"soil"];
        _pipeTexture2.filteringMode = SKTextureFilteringNearest;
        
        
        //CGFloat distanceToMove = self.frame.size.width + 2 * _pipeTexture1.size.width;
        SKAction* movePipes = [SKAction moveByX:-_pipeTexture1.size.width * 4 y:0 duration:0.02 * _pipeTexture1.size.width *2];
        SKAction* resetPipes = [SKAction moveByX:_pipeTexture1.size.width y:0 duration:0];
        _movePipesAndReset = [SKAction repeatActionForever:[SKAction sequence:@[movePipes, resetPipes]]];
        
        SKAction* spawn = [SKAction performSelector:@selector(spawnPipes) onTarget:self];
        SKAction* delay = [SKAction waitForDuration:0.68];
        SKAction* spawnThenDelay = [SKAction sequence:@[spawn, delay]];
        SKAction* spawnThenDelayForever = [SKAction repeatActionForever:spawnThenDelay];
        [self runAction:spawnThenDelayForever];
        
    }
    return self;
}


-(void)spawnPipes {
    SKNode* pipePair = [SKNode node];
    pipePair.position = CGPointMake(_mouse.size.width, 0 );
    pipePair.zPosition = -10;
    
    CGFloat y = arc4random() % (NSInteger)( self.frame.size.height / 8 );
    
    SKSpriteNode* pipe1 = [SKSpriteNode spriteNodeWithTexture:_pipeTexture1];
    [pipe1 setScale:1];
    pipe1.position = CGPointMake( 0, y );
    pipe1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipe1.size];
    pipe1.physicsBody.dynamic = NO;
    pipe1.physicsBody.categoryBitMask = pipeCategory;
    pipe1.physicsBody.contactTestBitMask = mouseCategory;
    
    [pipePair addChild:pipe1];
    
    SKSpriteNode* pipe2 = [SKSpriteNode spriteNodeWithTexture:_pipeTexture2];
    [pipe2 setScale:1];
    pipe2.position = CGPointMake( 0, y + pipe1.size.height + kVerticalPipeGap);
    pipe2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipe2.size];
    pipe2.physicsBody.dynamic = NO;
    pipe2.physicsBody.categoryBitMask = pipeCategory;
    pipe2.physicsBody.contactTestBitMask = mouseCategory;
    [pipePair addChild:pipe2];
    
    SKNode* contactNode = [SKNode node];
    contactNode.position = CGPointMake( pipe1.size.width, CGRectGetMidY( self.frame ) );
    contactNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(pipe2.size.width, self.frame.size.height)];
    contactNode.physicsBody.dynamic = NO;
    contactNode.physicsBody.categoryBitMask = scoreCategory;
    contactNode.physicsBody.contactTestBitMask = mouseCategory;
    [pipePair addChild:contactNode];
    
    [pipePair runAction:_movePipesAndReset];
    
    [_pipes addChild:pipePair];
}

-(void)resetScene {
    // Reset mouse properties
    _mouse.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
    _mouse.physicsBody.velocity = CGVectorMake( 0, 0 );
    _mouse.physicsBody.collisionBitMask = worldCategory | pipeCategory;
    _mouse.speed = 1.0;
    _mouse.zRotation = 0.0;
    
    // Remove all existing pipes
    [_pipes removeAllChildren];
    
    // Reset _canRestart
    _canRestart = NO;
    
    // Restart animation
    _moving.speed = 1;
    
    // Reset score
    //_score = 0;
    //_scoreLabelNode.text = [NSString stringWithFormat:@"%d", _score];
}


@end

